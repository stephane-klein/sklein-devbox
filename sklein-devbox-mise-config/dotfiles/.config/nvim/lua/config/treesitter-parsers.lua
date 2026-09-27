-- Single source of truth for the TreeSitter parsers to install.
-- Consumed both by the plugin spec (LazyVim `ensure_installed`, see
-- plugins/nvim-treesitter.lua) and by the bootstrap script
-- (install-treesitter-parsers.lua, run by ~/bin/install-or-update-neovim.sh).
return {
  -- Core Neovim
  "lua", "vim", "vimdoc", "markdown", "markdown_inline", "query",
  -- Web
  "html", "css", "javascript", "typescript", "tsx", "svelte", "astro",
  -- Go
  "go", "gomod", "gowork", "gosum",
  -- Python
  "python",
  -- Infrastructure
  "dockerfile", "terraform", "yaml",
  -- Data
  "json", "json5", "toml",
  -- SQL
  "sql",
  -- Script / Utils
  "bash", "regex", "luap", "luadoc", "printf",
  -- Oils (YSH)
  "ysh",
  -- System
  "c",
  -- Git
  "git_config", "git_rebase", "gitignore", "gitattributes", "gitcommit", "diff",
}
