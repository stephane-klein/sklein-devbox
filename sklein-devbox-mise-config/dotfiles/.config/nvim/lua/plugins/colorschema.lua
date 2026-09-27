return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night", -- maximum contrast
        contrast = {
          terminal = true,
          sidebars = true,
          floating_windows = true,
        },
        on_highlights = function(hl, c)
          hl.WinBar = {
            fg = c.fg,
            bg = c.bg_dark,
          }
          hl.WinBarNC = {
            fg = c.dark5
          }
          -- Make indent guides much more subtle
          hl.IblIndent = { fg = "NONE" }
          hl.IblScope = { fg = c.dark3 }
          hl.Whitespace = { fg = c.bg_highlight }
          
          -- Blocs de code markdown (style GitHub dark)
          hl.RenderMarkdownCode = { bg = c.bg_highlight }
          hl.RenderMarkdownCodeInline = { bg = c.bg_highlight }
        end,
      })
      vim.cmd([[colorscheme tokyonight]])
    end,
  }
}
