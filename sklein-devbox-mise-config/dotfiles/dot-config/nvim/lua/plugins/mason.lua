return {
  -- Mason core - on écrase tous les ensure_installed externes
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- Bloquer tous les ensure_installed venant d'autres plugins (extras LazyVim, etc.)
      opts.ensure_installed = {}
      return opts
    end,
  },

  -- Pont Mason ↔ LSP (pour les mappings de noms)
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- Pas de ensure_installed ici - géré par mason-tool-installer
      automatic_enable = false, -- On active manuellement via nvim-lspconfig
    },
  },

  -- Installation contrôlée des outils (lazy-loaded)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    cmd = {
      "MasonToolsInstall",
      "MasonToolsInstallSync",
      "MasonToolsUpdate",
      "MasonToolsUpdateSync",
      "MasonToolsClean",
    },
    opts = {
      ensure_installed = {
        -- Misc
        "prettierd",
        "terraform",

        -- Webdev (LSP)
        "css-lsp",
        "svelte-language-server",
        "typescript-language-server",
        "tailwindcss-language-server",
        "eslint-lsp",
        "astro-language-server",

        -- Golang (LSP + tools)
        "goimports",
        "gofumpt",
        "gopls",
        "golangci-lint",

        -- Script (LSP + tools)
        "shfmt",
        "bash-language-server",
        "shellcheck",

        -- Markdown
        "markdownlint-cli2",
        "markdown-toc",

        -- TOML
        "taplo",

        -- C/C++
        "clangd",
        "clang-format",
        "codelldb",

        -- Lua
        "lua-language-server",

        -- Sql
        "sqlfluff"
      },
      auto_update = false,
      run_on_start = false, -- ← Pas d'installation au démarrage
      integrations = {
        ["mason-lspconfig"] = true,
        ["mason-null-ls"] = false,
        ["mason-nvim-dap"] = false,
      },
    },
  },
}
