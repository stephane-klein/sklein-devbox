return {
  "NicholasZolton/neojj",
  version = "^1.0.0",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "esmuellert/codediff.nvim",
    "folke/snacks.nvim",
  },
  cmd = "Neojj",
  keys = {
    { "<leader>jj", "<cmd>Neojj<cr>", desc = "Show Neojj UI" }
  }
}
