-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable window-local directories
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  pattern = "*",
  callback = function()
    if vim.fn.haslocaldir() == 1 then
      vim.cmd("lcd -")  -- Reset to global cwd
    end
  end,
})

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.tpl",
  callback = function()
    vim.bo.filetype = "gotmpl"
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_rehighlight", { clear = true }),
  desc = "Re-apply Tree-sitter highlights after LSP attaches",
  callback = function(args)
    vim.schedule(function()
      pcall(vim.treesitter.stop, args.buf)
      pcall(vim.treesitter.start, args.buf)
    end)

    -- Re-applies our custom gd as buffer-local after Snacks' debounce (100ms)
    -- Snacks creates buffer-local LSP keymaps that shadow our global ones
    -- Cette étape garantit que notre gd (avec suivi d'import) reste actif
    vim.defer_fn(function()
      vim.keymap.set("n", "gld", function()
        local word = vim.fn.expand("<cword>")

        vim.api.nvim_echo({ { "gld: resolving " .. word .. "...", "MoreMsg" } }, false, {})

        local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" })
        if #clients == 0 then
          vim.notify("gld: no LSP client for definition", vim.log.levels.WARN)
          return
        end

        vim.lsp.buf.definition()

        vim.schedule(function()
          local line = vim.fn.getline(".")
          local pattern = "import%s+" .. vim.pesc(word) .. "%s+from%s+([\"'])(.-)%1"
          local import_path = line:match(pattern)
          if import_path then
            vim.api.nvim_echo({ { "gld: opening " .. import_path, "MoreMsg" } }, false, {})
            local dir = vim.fn.expand("%:p:h")
            vim.cmd("e " .. vim.fn.fnameescape(vim.fn.resolve(dir .. "/" .. import_path)))
          end
        end)
      end, { buffer = args.buf, desc = "Goto Definition" })
    end, 150)
  end,
})

