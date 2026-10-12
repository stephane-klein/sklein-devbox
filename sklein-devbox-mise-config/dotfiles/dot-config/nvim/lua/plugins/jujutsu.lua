return {
  {
    "evanphx/jjsigns.nvim",
    config = function()
      require('jjsigns').setup()

      local signs = require('jjsigns.signs')
      local original_place = signs.place_signs
      signs.place_signs = function(bufnr, signs_data)
        local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
        local filtered = {}
        for _, s in ipairs(signs_data) do
          if s.line - 1 < buf_line_count then
            table.insert(filtered, s)
          end
        end
        original_place(bufnr, filtered)
      end
    end
  },
  {
    "nicolasgb/jj.nvim",
    version = "*",
    dependencies = {
      "esmuellert/codediff.nvim",
    },
    config = function()
      require("jj").setup({
        diff = {
            backend = "codediff"
        }
      })
    end,
  }
}
