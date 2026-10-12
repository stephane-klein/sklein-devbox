-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- OSC 52 clipboard over SSH. Inside tmux Neovim prefers its built-in "tmux"
-- provider, whose paste reads tmux's own buffer, not the host clipboard. Force
-- OSC 52 so copy/paste round-trip through tmux (set-clipboard/get-clipboard)
-- to foot. Must run before any has('clipboard') call.
if vim.env.SSH_CONNECTION or vim.env.SSH_TTY or vim.env.SSH_CLIENT then
  vim.g.clipboard = "osc52"
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "*.lua",
  callback = function()
    vim.defer_fn(function()
      vim.wo.foldmethod = "marker"
      vim.wo.foldmarker = "{{{,}}}"
    end, 100)
  end,
})

vim.g.autoformat = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 10
vim.opt.smoothscroll = false

-- Disable LazyVim root detection completely
vim.g.lazyvim_root_disabled = true
vim.g.root_spec = { "cwd" }

-- Disable some annoying features like swapfile {{{
-- Disable swap files
vim.opt.swapfile = false

-- Disable backup files (file~)
vim.opt.backup = false
vim.opt.writebackup = false

-- Keep undo history but centralize it (useful feature to keep)
local undo_dir = vim.fn.stdpath('state') .. '/undo'
if vim.fn.isdirectory(undo_dir) == 0 then
  vim.fn.mkdir(undo_dir, 'p')
end
vim.opt.undofile = true
vim.opt.undodir = undo_dir
-- }}}

function _G.get_winbar()
  -- Get path relative to current working directory
  local filepath = vim.fn.expand("%:.")
  local modified = vim.bo.modified and " [+]" or ""
  local readonly = vim.bo.readonly and " [RO]" or ""

  -- Truncate from the left if too long
  local max_len = math.floor(vim.fn.winwidth(0) * 0.6)
  if #filepath > max_len then
    filepath = "..." .. filepath:sub(-(max_len - 3))
  end

  return filepath .. modified .. readonly
end

vim.opt.winbar = "%{%v:lua.get_winbar()%}"

-- Display dots (.) where indentation is built with spaces {{{
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  tab = "→ ",
  trail = "·",
}
-- }}}

-- Enable line wrapping by default {{{
vim.opt.wrap = true
vim.opt.linebreak = true -- Break lines at word boundaries (optional but recommended)
vim.opt.showbreak = "↪ " -- Visual indicator for wrapped lines (optional)
-- }}}

-- Notify WezTerm that we're in Neovim {{{
if os.getenv("TERM_PROGRAM") == "WezTerm" then
  -- Set IS_NVIM to true when entering Neovim
  io.write("\x1b]1337;SetUserVar=IS_NVIM=dHJ1ZQ==\007")
  io.flush()

  -- Reset when leaving Neovim
  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      io.write("\x1b]1337;SetUserVar=IS_NVIM=ZmFsc2U=\007")
      io.flush()
    end,
  })
end
-- }}}

vim.g.lazyvim_markdown_conceallevel = 0

vim.opt.clipboard = "unnamedplus"

vim.lsp.inlay_hint.enable(true)
