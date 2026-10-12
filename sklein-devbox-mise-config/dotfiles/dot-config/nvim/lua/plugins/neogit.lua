return {
  "NeogitOrg/neogit",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "dlyongemallo/diffview.nvim",
    -- "sindrets/diffview.nvim",
    "folke/snacks.nvim"
  },
  cmd = "Neogit",
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
  },
  opts = {
    commit_editor = {
      spell_check = false
    }
  }
}
