return {
  "folke/persistence.nvim",
  enabled = true,
  opts = {
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
  },
  keys = {
    {
      "<leader>qS",
      function()
        -- Trigger save event
        vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceSavePre" })
        -- Actually save the session
        require("persistence").save()
        vim.notify("Session saved with Neo-tree state!", vim.log.levels.INFO)
      end,
      desc = "Save Session Now"
    },
  },
  -- Auto-restore session when opening Neovim without arguments
  init = function()
    vim.api.nvim_create_autocmd("UIEnter", {
      group = vim.api.nvim_create_augroup("restore_session", { clear = true }),
      callback = function()
        if vim.fn.argc() == 0 then
          vim.schedule(function()
            require("persistence").load()
          end)
        end
      end,
      nested = true,
    })
  end,
}
