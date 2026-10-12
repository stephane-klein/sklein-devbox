return {
  {
    "carlos-algms/agentic.nvim",
    event = "VeryLazy",
    --- @type agentic.PartialUserConfig
    opts = {
      -- Configure opencode with ACP mode
      acp_providers = {
        ["opencode-acp"] = {
          name = "OpenCode",
          command = "opencode",
          args = { "acp" },
          initial_model = "opencode-go/kimi-k2.5",
        },
      },
      provider = "opencode-acp",
      -- Configure default layout (position right, width 40%)
      windows = {
        position = "right",
        width = "40%",
      },
      -- Configure widget keymaps
      keymaps = {
        widget = {
          switch_model = "<leader>am",  -- Switch model with <leader>am
        },
        prompt = {
          accept_completion = {
            { "<CR>", mode = { "i" } },
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      {
        "<C-c>",
        function() require("agentic").stop_generation() end,
        mode = { "n", "v", "i" },
        desc = "Stop current generation"
      },
      {
        "<C-a>",
        function() require("agentic").toggle() end,
        mode = { "n", "v", "i" },
        desc = "Toggle Agentic Chat"
      },
      {
        "<leader>ai",
        function() require("agentic").toggle() end,
        mode = { "n", "v" },
        desc = "Toggle Agentic Chat"
      },
      {
        "<leader>ac",
        function() require("agentic").add_selection_or_file_to_context() end,
        mode = { "n", "v" },
        desc = "Add file or selection to Agentic Context"
      },
      {
        "<leader>ad",
        function() require("agentic").add_current_line_diagnostics() end,
        mode = { "n" },
        desc = "Add current line diagnostics to Agentic"
      },
      {
        "<leader>aD",
        function() require("agentic").add_buffer_diagnostics() end,
        mode = { "n" },
        desc = "Add all buffer diagnostics to Agentic"
      },
      {
        "<leader>as",
        function() require("agentic").restore_session() end,
        mode = { "n", "v" },
        desc = "Restore Agentic session"
      },
      {
        "<leader>an",
        function() require("agentic").new_session() end,
        mode = { "n", "v" },
        desc = "Sart new chat session"
      },
      {
        "<leader>ar",
        function() require("agentic").rotate_layout() end,
        mode = { "n", "v" },
        desc = "Rotate window position through layouts"
      },
    },
  },
  -- Add which-key group for the <leader>a prefix
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "agentic" },
      },
    },
  },
}
