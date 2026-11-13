-- Reflow d'un paragraphe hard-wrappé en une seule ligne de buffer.
--
-- Un paragraphe tenu sur une ligne est la seule forme qui laisse 'wrap' remplir
-- la fenêtre : Neovim calcule le wrap à l'intérieur d'une ligne de buffer, jamais
-- à travers plusieurs. Avec le conceal, la 0.13 calcule en plus la largeur réelle
-- des caractères masqués, donc la ligne visuelle atteint bien le bord.

--- Refuse les blocs où joindre les lignes abîmerait le markdown (listes,
--- tableaux, citations, blocs de code) : `gqip` fusionnerait les puces.
local function is_safe(lines)
  for _, l in ipairs(lines) do
    if
      l:match("^%s*[-*+]%s")
      or l:match("^%s*%d+[.)]%s")
      or l:match("^%s*>")
      or l:match("^%s*|")
      or l:match("^%s*```")
    then
      return false
    end
  end
  return true
end

--- Reflow le paragraphe sous le curseur, ou la sélection visuelle.
--- `gq` découpe à 'textwidth' ; on la pousse très haut pour obtenir une ligne.
--- LazyVim installe un 'formatexpr' qui délègue à conform : on le neutralise,
--- sinon `gq` part chez le formateur au lieu de joindre les lignes.
local function unwrap(line1, line2)
  local first, last
  if line1 and line2 then
    first, last = line1, line2
  else
    -- Paragraphe sous le curseur : lignes contiguës non vides (indices 1-based).
    local all = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    first = vim.api.nvim_win_get_cursor(0)[1]
    last = first
    while first > 1 and all[first - 1]:match("%S") do
      first = first - 1
    end
    while last < #all and all[last + 1]:match("%S") do
      last = last + 1
    end
  end

  local block = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  if not is_safe(block) then
    vim.notify("MdUnwrap: bloc non textuel (liste, tableau, citation ou code)", vim.log.levels.WARN)
    return
  end

  local saved_tw = vim.bo.textwidth
  local saved_fex = vim.bo.formatexpr
  local saved_fp = vim.bo.formatprg
  vim.bo.textwidth = 100000
  vim.bo.formatexpr = ""
  vim.bo.formatprg = ""
  -- `:normal` avec une plage exécuterait `gq` ligne par ligne ; on passe donc
  -- par une sélection visuelle pour formater le bloc d'un seul coup.
  local ok, err = pcall(function()
    vim.api.nvim_win_set_cursor(0, { first, 0 })
    vim.cmd(("normal! V%dGgq"):format(last))
  end)
  vim.bo.textwidth = saved_tw
  vim.bo.formatexpr = saved_fex
  vim.bo.formatprg = saved_fp
  if not ok then
    vim.notify("MdUnwrap: " .. tostring(err), vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_user_command("MdUnwrap", function(args)
  -- range = 0 : aucune sélection, on prend le paragraphe sous le curseur.
  if args.range == 0 then
    unwrap(nil, nil)
  else
    unwrap(args.line1, args.line2)
  end
end, {
  range = true,
  desc = "Reflow le paragraphe markdown en une seule ligne",
})
