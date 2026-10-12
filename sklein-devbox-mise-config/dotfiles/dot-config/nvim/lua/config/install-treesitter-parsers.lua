local parsers = require("config.treesitter-parsers")

print("Installing Treesitter parsers: " .. table.concat(parsers, ", "))
local ok, err = pcall(function()
  require("nvim-treesitter").install(parsers, { summary = true }):wait(900000)
end)
if not ok then
  print("ERROR: " .. tostring(err))
  vim.cmd("cquit 1")
end

local installed = require("nvim-treesitter").get_installed("parsers")
local missing = vim.tbl_filter(function(lang)
  return not vim.tbl_contains(installed, lang)
end, parsers)
if #missing > 0 then
  print("ERROR: missing parsers: " .. table.concat(missing, ", "))
  vim.cmd("cquit 1")
end
print("Done.")
