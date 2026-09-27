return {
  "klen/nvim-config-local",
  opts = {
    -- Config file patterns to load (in order)
    config_files = { ".nvim.lua", ".nvimrc.lua", ".exrc.lua" },

    -- Where the plugin keeps files data
    hashfile = vim.fn.stdpath("data") .. "/config-local",

    -- Auto-create commands (:ConfigLocalSource, :ConfigLocalEdit, :ConfigLocalTrust, :ConfigLocalIgnore)
    commands_create = true,

    -- Auto-create autocommands to load config on DirChanged
    autocommands_create = true,

    -- Don't ask for confirmation (use with caution!)
    silent = false,

    -- Look for config files in parent directories
    lookup_parents = true,
  },
}
