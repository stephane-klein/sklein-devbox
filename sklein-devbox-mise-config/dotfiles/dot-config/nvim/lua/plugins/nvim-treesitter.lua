return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    -- LazyVim merges this with its own defaults (`opts_extend`), so the parsers
    -- listed here are added to LazyVim's `ensure_installed`.
    ensure_installed = require("config.treesitter-parsers"),
  },
  init = function()
    -- Custom parser: YSH (Oils shell)
    -- Registered in a `User TSUpdate` autocommand, as documented by nvim-treesitter.
    local function register_ysh()
      require("nvim-treesitter.parsers").ysh = {
        install_info = {
          url = "https://github.com/danyspin97/tree-sitter-ysh",
          branch = "main",
        },
      }
    end
    register_ysh()
    vim.api.nvim_create_autocmd("User", {
      pattern = "TSUpdate",
      callback = register_ysh,
    })
  end,
}
