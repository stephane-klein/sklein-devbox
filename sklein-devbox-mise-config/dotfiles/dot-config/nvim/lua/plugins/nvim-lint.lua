local cache = {}

local function check_markdownlint()
  local bufnr = vim.api.nvim_get_current_buf()
  if cache[bufnr] == nil then
    local root = vim.fs.root(bufnr, {
      ".markdownlint.json",
      ".markdownlint.jsonc",
      ".markdownlint.yaml",
      ".markdownlint.yml",
    })
    cache[bufnr] = root ~= nil
  end
  return cache[bufnr]
end

vim.api.nvim_create_autocmd({ "BufRead", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("markdownlint_conditional", { clear = true }),
  pattern = "*.md",
  callback = function()
    if check_markdownlint() then
      require("lint").try_lint("markdownlint-cli2")
    end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    cache[args.buf] = nil
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    cache = {}
  end,
})

return {
  "mfussenegger/nvim-lint",
  enabled = true,
}
