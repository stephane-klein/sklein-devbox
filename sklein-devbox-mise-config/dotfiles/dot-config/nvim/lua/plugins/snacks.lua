return {
  "folke/snacks.nvim",
  keys = {
    { "<leader><space>", false }, -- Because I use custom keymap based on <space><space> to split windows
    { "<leader>.",       false }, -- Because I use <leader>. to open floating neo-tree
    {
      "<leader>fI",
      function()
        LazyVim.pick("files", { ignored = false })()
      end,
      desc = "Find Files (Root Dir, no ignored)",
    },
  },
  ---@type snacks.Config
  opts = function(_, opts)
    vim.api.nvim_set_hl(0, "SnacksPickerToggleHidden", { fg = "#ff8800", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerToggleIgnored", { fg = "#888888", bold = true })
    return vim.tbl_deep_extend("force", opts or {}, {
      animate = {
        enabled = false
      },
      scroll = {
        enabled = false
      },
      picker = {
        sources = {
          files = {
            hidden = true,
            ignored = true,
          },
          grep = {
            hidden = true,
          },
        },
        toggles = {
          hidden = { icon = "H" },
          ignored = { icon = "I" },
        },
        layouts = {
          vertical = {
            layout = {
              title = "{title} {live} {flags} | hints: <a-h> <a-i> <ctrl-up> <ctrl-down>",
              width = 0.9,
              height = 0.9,
            },
          },
        },
        layout = {
          preset = "vertical",
        },
      },
      zen = {
        toggles = {
          dim = false,
        },
      },
      styles = {
        zen = {
          backdrop = { transparent = false, blend = 30 },
          keys = { q = "close" },
        },
      },
    })
  end,
}
