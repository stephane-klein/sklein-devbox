-- Aperçu markdown en lecture seule, via le binaire `glow` (déclaré dans la
-- config mise globale, côté machine).
--
-- L'aperçu prend la place du pane courant : `q` ramène le buffer d'origine.
-- Les cibles des liens sont retirées avant le rendu, parce qu'elles saturent
-- l'aperçu ; le buffer markdown, lui, les révèle sur la ligne du curseur (voir
-- 'concealcursor' dans lua/config/autocmds.lua).

if vim.fn.executable("glow") == 0 then
  return
end

-- Neovim 0.13 répond aux requêtes OSC 10/11 (couleur de fond du terminal) depuis
-- un handler de TermRequest qui n'attrape pas l'erreur. Glow interroge le
-- terminal puis se termine aussitôt : la réponse arrive sur un canal fermé et
-- Neovim affiche « Can't send data to closed stream ». On remplace ce handler
-- par la même logique, protégée par pcall. À supprimer quand Neovim corrige.
do
  local group = "nvim.terminal"
  for _, au in ipairs(vim.api.nvim_get_autocmds({ group = group, event = "TermRequest" })) do
    if (au.desc or ""):match("OSC foreground/background") then
      vim.api.nvim_del_autocmd(au.id)
    end
  end

  vim.api.nvim_create_autocmd("TermRequest", {
    group = group,
    desc = "Replies to OSC 10/11, ignoring a closed channel",
    callback = function(ev)
      local channel = vim.bo[ev.buf].channel
      if channel == 0 then
        return
      end
      local fg_request = ev.data.sequence == "\027]10;?"
      local bg_request = ev.data.sequence == "\027]11;?"
      if not (fg_request or bg_request) then
        return
      end
      local dark = vim.o.background == "dark"
      local r, g, b = 0, 0, 0
      if (fg_request and dark) or (bg_request and not dark) then
        r, g, b = 65535, 65535, 65535
      end
      local command = fg_request and 10 or 11
      local data = string.format("\027]%d;rgb:%04x/%04x/%04x%s", command, r, g, b, ev.data.terminator)
      pcall(vim.api.nvim_chan_send, channel, data)
    end,
  })
end

--- Remplace [texte](cible) et [texte][ref] par leur seul texte, hors blocs de
--- code, pour que glow n'affiche pas les URLs.
---@param lines string[]
---@return string[]
local function strip_link_targets(lines)
  local out = {}
  local infence = false
  for _, line in ipairs(lines) do
    if line:match("^%s*```") or line:match("^%s*~~~") then
      infence = not infence
      out[#out + 1] = line
    elseif infence then
      out[#out + 1] = line
    else
      local stripped = line
        :gsub("!%[([^%]]*)%]%([^%)]*%)", "%1")
        :gsub("%[([^%]]*)%]%([^%)]*%)", "%1")
        :gsub("%[([^%]]*)%]%[[^%]]*%]", "%1")
      out[#out + 1] = stripped
    end
  end
  return out
end

--- Aperçu courant, pour pouvoir le redessiner quand le pane change de largeur.
---@type { win: integer, origin: integer, buf: integer, width: integer, timer: integer? }|nil
local state = nil

--- Complète les lignes des blocs de code par des espaces jusqu'à `width - 6`.
--- Glamour rend les blocs via chroma, qui ne peint le fond que sur le texte :
--- sans ce remplissage, le fond s'arrête au dernier caractère de chaque ligne.
---@param lines string[]
---@param width integer
---@return string[]
local function pad_code_lines(lines, width)
  local out = {}
  local infence = false
  local target = math.max(0, width - 6)
  for _, line in ipairs(lines) do
    if line:match("^%s*```") or line:match("^%s*~~~") then
      infence = not infence
      out[#out + 1] = line
    elseif infence and #line < target then
      out[#out + 1] = line .. string.rep(" ", target - #line)
    else
      out[#out + 1] = line
    end
  end
  return out
end

--- Rend `origin` dans `win` avec glow, à la largeur `width`.
local function render(win, origin, width)
  local tmp = vim.fn.tempname() .. ".md"
  local body = pad_code_lines(strip_link_targets(vim.api.nvim_buf_get_lines(origin, 0, -1, false)), width)
  vim.fn.writefile(body, tmp)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_win_set_buf(win, buf)

  vim.wo[win].wrap = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false

  -- `jobstart(..., { term = true })` rattache le job au buffer *courant*, et
  -- refuse un buffer modifié. Depuis une minuterie de redimensionnement, le
  -- buffer courant est celui que regarde l'utilisateur, souvent le markdown
  -- modifié. On se place donc explicitement sur la fenêtre de l'aperçu, puis on
  -- rend le focus à la fenêtre d'origine.
  local prev_win = vim.api.nvim_get_current_win()
  if prev_win ~= win then
    vim.api.nvim_set_current_win(win)
  end
  -- `jobstart` peut lever une erreur (buffer modifié, par exemple) plutôt que
  -- renvoyer un code : on l'attrape pour ne pas laisser l'aperçu dans un état
  -- incohérent sans le dire.
  -- Même thème que la commande `glow` : un seul fichier, dans ~/.config/glow,
  -- décrit par glow.yml. On retombe sur le style intégré s'il manque.
  local style = vim.fn.expand("~/.config/glow/catppuccin-mocha.json")
  if vim.fn.filereadable(style) == 0 then
    style = "dark"
  end

  local ok, job = pcall(vim.fn.jobstart, { "glow", "-s", style, "-w", tostring(width), tmp }, {
    term = true,
  })
  if prev_win ~= win and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
  if not ok or type(job) ~= "number" or job <= 0 then
    vim.notify("Glow: échec du lancement (" .. tostring(job) .. ")", vim.log.levels.ERROR)
    vim.fn.delete(tmp)
    vim.api.nvim_win_set_buf(win, origin)
    return nil
  end

  -- Le job nomme le buffer `term://…/glow` ; on lui donne un nom court pour la
  -- tabline et la bufferline.
  pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(origin), ":t"))

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function()
      vim.fn.delete(tmp)
    end,
  })

  local function back()
    if vim.api.nvim_buf_is_valid(origin) then
      vim.api.nvim_win_set_buf(win, origin)
    else
      vim.cmd("enew")
    end
  end

  vim.keymap.set("n", "q", back, { buffer = buf, desc = "Quitter l'aperçu" })
  vim.keymap.set("n", "<leader>um", back, { buffer = buf, desc = "Quitter l'aperçu" })

  return buf
end

--- Largeur utile pour glow : le pane, moins la marge des deux côtés.
local function usable_width(win)
  return math.max(40, vim.api.nvim_win_get_width(win) - 4)
end

local function open_glow()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Le buffer courant n'est associé à aucun fichier.", vim.log.levels.WARN)
    return
  end

  local origin = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local width = usable_width(win)

  -- Les liens sont retirés dans un fichier temporaire plutôt que passés sur
  -- stdin : avec `term = true`, Neovim branche l'entrée du job sur le
  -- pseudo-terminal, et glow rend alors sans aucun style.
  local buf = render(win, origin, width)
  if not buf then
    return
  end

  state = { win = win, origin = origin, buf = buf, width = width }
end

-- Glow wrappe son propre texte : suivre le redimensionnement demande un nouveau
-- rendu. On temporise, un glissement de bord produit beaucoup d'événements.
vim.api.nvim_create_autocmd("WinResized", {
  group = vim.api.nvim_create_augroup("glow_resize", { clear = true }),
  callback = function()
    if not state or not vim.api.nvim_buf_is_valid(state.buf) or not vim.api.nvim_win_is_valid(state.win) then
      return
    end
    if vim.api.nvim_win_get_buf(state.win) ~= state.buf then
      return
    end
    local width = usable_width(state.win)
    if width == state.width then
      return
    end
    if state.timer then
      vim.fn.timer_stop(state.timer)
    end
    state.timer = vim.fn.timer_start(200, function()
      state.timer = nil
      if not state or not vim.api.nvim_buf_is_valid(state.buf) or not vim.api.nvim_win_is_valid(state.win) then
        return
      end
      if vim.api.nvim_win_get_buf(state.win) ~= state.buf then
        return
      end
      local new_width = usable_width(state.win)
      if new_width == state.width then
        return
      end
      local buf = render(state.win, state.origin, new_width)
      if buf then
        state.buf = buf
        state.width = new_width
      end
    end)
  end,
})

vim.api.nvim_create_user_command("Glow", open_glow, {
  desc = "Aperçu markdown du fichier courant avec glow",
})

vim.keymap.set("n", "<leader>um", "<cmd>Glow<cr>", { desc = "Aperçu markdown (glow)" })
