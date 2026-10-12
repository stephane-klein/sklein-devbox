return {
  "nvim-lualine/lualine.nvim",
  enabled = true,
  opts = function(_, opts)
    opts.sections.lualine_c = {
      {
        function()
          local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
          local width = vim.o.columns
          local max_len = math.floor(width * 0.25)

          if #cwd <= max_len then
            return cwd
          end

          -- Smart truncation: keep last path segments
          local parts = vim.split(cwd, "/")
          local result = parts[#parts]   -- always keep last segment

          for i = #parts - 1, 1, -1 do
            local candidate = parts[i] .. "/" .. result
            if #candidate + 3 > max_len then
              return ".../" .. result
            end
            result = candidate
          end

          return result
        end,
        icon = "󰉋",
      },
    }
  end,
}
