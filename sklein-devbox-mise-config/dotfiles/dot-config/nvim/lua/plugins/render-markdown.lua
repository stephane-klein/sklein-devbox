return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = true,
    opts = {
      enabled = false,
      
      win_options = {
        conceallevel = {
          default = 0,
          rendered = 2,
        },
        concealcursor = {
          default = "",
          rendered = "nc",
        },
      },
      
      -- Désactiver le rendu en mode insertion
      render_modes = { "n", "c" }, -- Seulement normal et command, pas insertion
      anti_conceal = {
        enabled = false,
      },
      
      heading = {
        enabled = true,
        sign = false,
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
        backgrounds = {},
        foregrounds = {
          "RenderMarkdownH1",
          "RenderMarkdownH2", 
          "RenderMarkdownH3",
          "RenderMarkdownH4",
          "RenderMarkdownH5",
          "RenderMarkdownH6",
        },
      },
      
      code = {
        enabled = true,
        sign = false,
        style = "normal",
        position = "left",
        width = "block",
        left_pad = 1,
        right_pad = 1,
        min_width = 80,
        border = "thin",
        above = "▄",
        below = "▀",
        highlight = "RenderMarkdownCode",
        highlight_inline = "RenderMarkdownCodeInline",
      },
      
      bullet = {
        enabled = true,
        icons = { "•", "◦", "▪", "▫" },
      },
      
      checkbox = {
        enabled = true,
        unchecked = { icon = "☐ " },
        checked = { icon = "☑ " },
      },
      
      quote = {
        enabled = true,
        icon = "▌",
      },
      
      pipe_table = {
        enabled = true,
        preset = "round",
        style = "full",
        cell = "padded",
        alignment_indicator = "━",
        head = "RenderMarkdownTableHead",
        row = "RenderMarkdownTableRow",
        padding = 1
      },
    },
    
    keys = {
      {
        "<leader>um",
        "<cmd>RenderMarkdown toggle<cr>",
        desc = "Toggle Markdown Render",
      },
    },
  },
}

-- return {
--   "MeanderingProgrammer/render-markdown.nvim",
--   enabled = false,
--   opts = {
--     completions = {
--       lsp = { enabled = true }
--     },
--     paragraph = {
--       min_width = 100,
--     },
--     code = {
--       width = "block",
--       left_pad = 2,
--       right_pad = 4,
--     },
--     heading = {
--       width = "block",
--       left_pad = 0,
--       right_pad = 1,
--       position = "inline",
--       icons = false,
--     },
--     win_options = {
--       conceallevel = {
--         default = vim.api.nvim_get_option_value('conceallevel', {}),
--         rendered = 3,
--       },
--       concealcursor = {
--         default = vim.api.nvim_get_option_value('concealcursor', {}),
--         rendered = 'nc',
--       },
--     },
--     anti_conceal = {
--       enabled = false,
--     }
--   }
-- }
