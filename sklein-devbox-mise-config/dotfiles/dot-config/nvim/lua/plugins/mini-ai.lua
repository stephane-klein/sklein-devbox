-- mini.ai with treesitter textobjects support
-- Replaces nvim-treesitter-textobjects, works with tree-sitter-manager
return {
  "nvim-mini/mini.ai",
  version = false,
  dependencies = {},
  config = function()
    local spec_treesitter = require("mini.ai").gen_spec.treesitter

    require("mini.ai").setup({
      n_lines = 50,
      search_method = "cover_or_next",
      silent = false,

      custom_textobjects = {
        -- Function definition
        F = spec_treesitter({
          a = "@function.outer",
          i = "@function.inner",
        }),

        -- Class/struct/namespace
        C = spec_treesitter({
          a = "@class.outer",
          i = "@class.inner",
        }),

        -- Loop and conditional combined
        o = spec_treesitter({
          a = { "@conditional.outer", "@loop.outer" },
          i = { "@conditional.inner", "@loop.inner" },
        }),

        -- Loop only
        l = spec_treesitter({
          a = "@loop.outer",
          i = "@loop.inner",
        }),

        -- Conditional only
        c = spec_treesitter({
          a = "@conditional.outer",
          i = "@conditional.inner",
        }),

        -- Block (function body, etc.)
        b = spec_treesitter({
          a = "@block.outer",
          i = "@block.inner",
        }),

        -- Parameter/argument
        a = spec_treesitter({
          a = "@parameter.outer",
          i = "@parameter.inner",
        }),

        -- Assignment
        A = spec_treesitter({
          a = "@assignment.outer",
          i = "@assignment.inner",
        }),
      },
    })

    -- Keymaps for treesitter textobjects
    -- Examples: viF (inner function), vaC (around class), vio (inner loop/conditional)

    -- Go to next/previous function
    vim.keymap.set({ "n", "x", "o" }, "]f", function()
      require("mini.ai").move_cursor("right", "a", "F", { search_method = "next" })
    end, { desc = "Next function start" })

    vim.keymap.set({ "n", "x", "o" }, "[f", function()
      require("mini.ai").move_cursor("left", "a", "F", { search_method = "prev" })
    end, { desc = "Previous function start" })

    -- Go to next/previous class
    vim.keymap.set({ "n", "x", "o" }, "]c", function()
      require("mini.ai").move_cursor("right", "a", "C", { search_method = "next" })
    end, { desc = "Next class start" })

    vim.keymap.set({ "n", "x", "o" }, "[c", function()
      require("mini.ai").move_cursor("left", "a", "C", { search_method = "prev" })
    end, { desc = "Previous class start" })
  end,
}
