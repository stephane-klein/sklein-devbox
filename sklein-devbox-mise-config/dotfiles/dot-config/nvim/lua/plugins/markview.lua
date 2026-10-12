return {
  {
    "OXY2DEV/markview.nvim",
    enabled = false,
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      modes = { "n", "c" }, -- Seulement en mode normal et command
      hybrid_modes = nil, -- Pas de mode hybride
      
      callbacks = {
        on_enable = function(_, win)
          vim.wo[win].conceallevel = 2
          vim.wo[win].concealcursor = "nc"
        end,
        on_disable = function(_, win)
          vim.wo[win].conceallevel = 0
          vim.wo[win].concealcursor = ""
        end,
      },
      
      headings = {
        enable = true,
        shift_width = 0,
        heading_1 = {
          style = "simple",
          sign = "",
          icon = "# ",
        },
        heading_2 = {
          style = "simple",
          sign = "",
          icon = "## ",
        },
        heading_3 = {
          style = "simple",
          sign = "",
          icon = "### ",
        },
        heading_4 = {
          style = "simple",
          sign = "",
          icon = "#### ",
        },
        heading_5 = {
          style = "simple",
          sign = "",
          icon = "##### ",
        },
        heading_6 = {
          style = "simple",
          sign = "",
          icon = "###### ",
        },
      },
      
      code_blocks = {
        enable = true,
        style = "simple",
        position = "overlay",
        min_width = 80,
        pad_amount = 1,
        hl = "MarkviewCode",
      },
      
      inline_codes = {
        enable = true,
        hl = "MarkviewInlineCode",
      },
      
      links = {
        enable = true,
        hyperlinks = {
          icon = " ",
          hl = "MarkviewHyperlink",
        },
        images = {
          icon = " ",
          hl = "MarkviewImage",
        },
      },
      
      list_items = {
        enable = true,
        indent_size = 2,
        shift_width = 2,
        marker_minus = {
          text = "•",
        },
        marker_plus = {
          text = "◦",
        },
        marker_star = {
          text = "▪",
        },
      },
      
      checkboxes = {
        enable = true,
        unchecked = {
          text = "☐",
        },
        checked = {
          text = "☑",
        },
      },
      
      block_quotes = {
        enable = true,
        default = {
          border = "▌",
        },
      },
      
      tables = {
        enable = true,
        text = {
          top = { "┌", "─", "┬", "┐" },
          header = { "├", "─", "┼", "┤" },
          separator = { "│", "│" },
          bottom = { "└", "─", "┴", "┘" },
        },
        hl = {
          "MarkviewTableHeader",
          "MarkviewTableRow",
        },
      },
    },
    
    config = function(_, opts)
      require("markview").setup(opts)
      
      -- Désactiver par défaut
      vim.cmd("Markview disableAll")
    end,
    
    keys = {
      {
        "<leader>um",
        "<cmd>Markview toggle<cr>",
        desc = "Toggle Markdown Render",
      },
    },
  },
}
