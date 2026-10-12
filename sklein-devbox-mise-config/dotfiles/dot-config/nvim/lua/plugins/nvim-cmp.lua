return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
  },
  opts = function(_, opts)
    local cmp = require("cmp")
    
    -- Disable auto-completion
    opts.completion = {
      autocomplete = false, -- Disable auto-trigger
    }
    
    -- Disable ghost text
    opts.experimental = {
      ghost_text = false,
    }
    
    -- Configure keymaps
    opts.mapping = cmp.mapping.preset.insert({
      ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
      ["<Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
      ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
      ["<S-Tab>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<ESC>"] = cmp.mapping(function()
        if cmp.visible() then
          cmp.close()
        else
          -- Send Ctrl-C to exit insert mode
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), "n", true)
        end
      end, { "i", "s" }),
      ["<C-space>"] = cmp.mapping.complete(), -- Manually trigger completion
    })
    
    -- Configure buffer source to use all buffers
    for _, source in ipairs(opts.sources or {}) do
      if source.name == "buffer" then
        source.option = {
          get_bufnrs = function()
            return vim.api.nvim_list_bufs()
          end
        }
        break
      end
    end

    -- Disable nvim-cmp in agentic.nvim prompt buffers so that
    -- the file picker completion (triggered by @) can use <CR>
    -- to accept selections without conflicts.
    cmp.setup.filetype("AgenticInput", {
      enabled = false,
      sources = {},
    })

    return opts
  end,
}
