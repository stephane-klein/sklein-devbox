return {
  "nvim-mini/mini.align",
  opts = {
    mappings = {
      start = 'ga',
      start_with_preview = 'gA',
    }
  },
  keys = {
    { "ga", mode = { "n", "x" } },
    { "gA", mode = { "n", "x" } }
  }
}
