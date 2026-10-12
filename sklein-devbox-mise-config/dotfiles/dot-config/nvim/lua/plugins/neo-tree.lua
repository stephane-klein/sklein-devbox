-- File: lua/plugins/neo-tree.lua
--
-- Integrates jj VCS status into Neo-tree's filesystem view.
-- Only active in pure jj repos (presence of .jj/).
-- In regular git repos, Neo-tree uses its native git behavior.

-- Walk up the directory tree to find the jj repo root
local function find_jj_root(path)
  local dir = path
  while dir ~= "/" do
    if vim.fn.isdirectory(dir .. "/.jj") == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return nil
end

-- Internal state: debounce timer and running lock
local jj_debounce_timer = nil
local jj_refresh_running = false

-- Run jj diff --summary asynchronously and populate the cache
local function refresh_jj_status()
  -- Prevent concurrent calls
  if jj_refresh_running then return end

  local cwd = vim.fn.getcwd()
  local jj_root = find_jj_root(cwd)

  -- Not a jj repo: clear cache and let Neo-tree handle git natively
  if not jj_root then
    jj_status_cache = {}
    return
  end

  jj_refresh_running = true

  vim.system(
    { "jj", "diff", "--summary", "--no-pager" },
    {
      cwd = jj_root,
      text = true,
    },
    function(result)
      jj_refresh_running = false

      if result.code ~= 0 then return end

      local git_status = {}
      local status_map = { A = "A ", M = "M ", D = "D ", R = "R " }

      for line in result.stdout:gmatch("[^\n]+") do
        local status, path = line:match("^([AMDR]) (.+)$")
        if status and path then
          local full_path = jj_root .. "/" .. path
          git_status[full_path] = status_map[status] or "M "
        end
      end

      -- Inject into neo-tree's internal git worktree cache and trigger a refresh
      vim.schedule(function()
        local ok, git = pcall(require, "neo-tree.git")
        if not ok then return end

        -- Register a fake worktree for the jj root if not already present
        if not git.worktrees[jj_root] then
          git.worktrees[jj_root] = {
            status = {},
            status_diff = {},
            status_progress = {},
          }
        end

        -- Inject jj status into the worktree status table
        git.worktrees[jj_root].status = git_status

        -- Invalidate the upward path cache so all paths are re-resolved
        git._upward_worktree_cache = setmetatable({}, { __mode = "kv" })

        local mok, manager = pcall(require, "neo-tree.sources.manager")
        if mok then
          manager.refresh("filesystem")
        end
      end)
    end
  )
end

-- Debounced version: waits 150ms after the last call before running
local function refresh_jj_status_debounced()
  if jj_debounce_timer then
    jj_debounce_timer:stop()
    jj_debounce_timer:close()
    jj_debounce_timer = nil
  end

  jj_debounce_timer = vim.defer_fn(function()
    jj_debounce_timer = nil
    refresh_jj_status()
  end, 150)
end

return {
  {
    "stephane-klein/neo-tree.nvim",
    enabled = true,
    cmd = "Neotree",
    keys = {
      {
        "<leader>.",
        function()
          require("neo-tree.command").execute({
            position = "current",
            toggle = true,
            dir = vim.fn.expand('%:p:h')
          })
        end,
        desc = "Explorer float NeoTree"
      },
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ action = "focus" })
        end,
        desc = "Focus Neo-tree",
      },
      {
        "<leader>fec",
        function()
          require("neo-tree.command").execute({ action = "close" })
        end,
        desc = "Close NeoTree",
      }
    },
    deactivate = function()
      vim.cmd([[Neotree close]])
    end,
    init = function()
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
        desc = "Start Neo-tree with directory",
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            return
          else
            local stats = vim.uv.fs_stat(vim.fn.argv(0) --[[@as string]])
            if stats and stats.type == "directory" then
              require("neo-tree")
            end
          end
        end,
      })

      -- Refresh jj status on every file write
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("Neotree_jj_status", { clear = true }),
        callback = refresh_jj_status_debounced,
      })
    end,
    opts = {
      sources = { "filesystem" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      hijack_netrw_behavior = "open_default",
      -- Native git status is still enabled for git repos
      -- (automatically ignored when no .git is present)
      enable_git_status = true,
      filesystem = {
        auto_expand_width = true,
        bind_to_cwd = true,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = true
        },
        use_libuv_file_watcher = true,
        window = {
          mappings = {
            ["."] = {
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                if node.type ~= "directory" then
                  path = vim.fn.fnamemodify(path, ":h")
                end
                vim.cmd("cd " .. vim.fn.fnameescape(path))
              end,
              desc = "Set root and change global pwd",
            },
            ["e"] = {
              "toggle_auto_expand_width",
              desc = "Toggle auto expand width",
            },
            ["<leader>/"] = {
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                if node.type ~= "directory" then
                  path = vim.fn.fnamemodify(path, ":h")
                end
                require("snacks").picker.grep({ cwd = path })
              end,
              desc = "Grep in directory",
            },
          },
        },
      },
      window = {
        mappings = {
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path, "c")
            end,
            desc = "Copy Path to Clipboard",
          },
          ["P"] = { "toggle_preview", config = { use_float = true } },
        },
      },
      default_component_configs = {
        indent = {
          with_expanders = true,
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            unstaged = "󰄱",
            staged = "󰱒",
          },
        },
      },
    },
    config = function(_, opts)
      local function on_move(data)
        Snacks.rename.on_rename_file(data.source, data.destination)
      end

      local events = require("neo-tree.events")
      opts.event_handlers = opts.event_handlers or {}
      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED,   handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
        -- Trigger a jj refresh on initial Neo-tree render
        {
          event = events.VIM_BUFFER_ENTER,
          handler = function()
            refresh_jj_status_debounced()
          end,
        },
      })

      require("neo-tree").setup(opts)

      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit",
        callback = function()
          if package.loaded["neo-tree.sources.git_status"] then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stephane-klein/neo-tree.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        hint = "floating-big-letter",
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },
  {
    "stephane-klein/neo-tree-session.nvim",
    dependencies = {
      "stephane-klein/neo-tree.nvim",
      "folke/persistence.nvim"
    },
    opts = {}
  }
}
