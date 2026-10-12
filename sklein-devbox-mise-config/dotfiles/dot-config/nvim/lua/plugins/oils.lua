return {
  {
    "oils-for-unix/oils.vim",
    config = function()
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = "*.sh",
        callback = function()
          local line = vim.fn.getline(1)
          if line:match("^#!/usr/bin/env osh") then
            vim.bo.filetype = "ysh"
          end
        end,
      })
    end,
  },
}
