return {
  "stephane-klein/mise-treesitter-queries.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("mise-treesitter-queries").setup()
  end,
}
