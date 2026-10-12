-- I don't use LazyVim overseer extra because 2.0.0 breaking changes https://github.com/stevearc/overseer.nvim/releases/tag/v2.0.0
-- See https://github.com/LazyVim/LazyVim/issues/6876
return {
  {
    "catppuccin",
    opts = {
      integrations = { overseer = true },
    },
  },
  {
    "stevearc/overseer.nvim",
    lazy = false, -- plugin is self-lazy-loading
    cmd = {
      "OverseerOpen",
      "OverseerClose",
      "OverseerToggle",
      "OverseerRun",
      "OverseerTaskAction",
    },
    opts = {
      dap = false,
      task_list = {
        keymaps = {
          ["<C-j>"] = false,
          ["<C-k>"] = false,
        },
      },
      form = {
        win_opts = {
          winblend = 0,
        },
      },
      task_win = {
        win_opts = {
          winblend = 0,
        },
      },
    },
    -- stylua: ignore
    keys = {
      { "<leader>ow", "<cmd>OverseerToggle!<cr>",    desc = "Task list" },
      { "<leader>oo", "<cmd>OverseerRun<cr>",        desc = "Run task" },
      { "<leader>ot", "<cmd>OverseerTaskAction<cr>", desc = "Task action" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>o", group = "overseer" },
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      require("overseer").enable_dap()
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, { "overseer" })
    end,
  }
}
