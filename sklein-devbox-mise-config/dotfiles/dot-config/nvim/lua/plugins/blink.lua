return {
  "saghen/blink.cmp",
  enabled = false,
  opts = {
    keymap = {
      preset = "default",
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Tab>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
      ["<C-e>"] = { "hide", "fallback" },
      ["<ESC>"] = {
        function(cmp) -- Hack found here https://github.com/saghen/blink.cmp/issues/547#issuecomment-2593493560
          if cmp.is_visible() then
            cmp.cancel()
          else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), "n", true)
          end
        end,
      },
      ["<C-space>"] = { "show", "fallback" },
    },
    completion = {
      menu = {
        auto_show = false,
      },
      trigger = {
        show_on_keyword = false,
        show_on_insert_on_trigger_character = false,
      },
      ghost_text = {
        enabled = false,
      },
    },
  },
}
