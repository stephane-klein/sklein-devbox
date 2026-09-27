return {
  {
    "neovim/nvim-lspconfig",
    version = "v2.4.0",
    config = function()
      -- Configuration des serveurs LSP via l'API native Neovim 0.11+
      -- Les configurations sont mergées avec celles de nvim-lspconfig

      -- ESLint
      vim.lsp.config('eslint', {
        -- root_dir = function(fname)
        --   local util = require("lspconfig.util")
        --   return util.root_pattern(
        --     ".eslintrc",
        --     ".eslintrc.js",
        --     ".eslintrc.cjs",
        --     ".eslintrc.yaml",
        --     ".eslintrc.yml",
        --     ".eslintrc.json",
        --     "eslint.config.js",
        --     "eslint.config.mjs",
        --     "eslint.config.cjs",
        --     "package.json"
        --   )(fname)
        -- end,
      })

      -- vtsls (TypeScript)
      vim.lsp.config('vtsls', {
        -- root_dir = function(fname)
        --   local util = require("lspconfig.util")
        --   return util.root_pattern(
        --     "tsconfig.json",
        --     "jsconfig.json",
        --     "package.json",
        --     ".git"
        --   )(fname)
        -- end,
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                {
                  name = "typescript-svelte-plugin",
                  location = require("mason-registry")
                    .get_package("svelte-language-server")
                    :get_install_path()
                    .. "/node_modules/typescript-svelte-plugin",
                  enableForWorkspaceTypeScriptVersions = true,
                },
              },
            },
          },
        },
      })

      -- clangd (C/C++)
      vim.lsp.config('clangd', {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders=true",
        },
      })

      -- svelte
      vim.lsp.config('svelte', {
        settings = {
          svelte = {
            plugin = {
              typescript = {
                enable = true,
                diagnostics = { enable = true },
                hover = { enable = true },
                completions = { enable = true },
                documentSymbols = { enable = true },
                codeActions = { enable = true },
                selectionRange = { enable = true },
                signatureHelp = { enable = true },
                semanticTokens = { enable = true },
                workspaceSymbols = { enable = true },
              },
              svelte = {
                enable = true,
                diagnostics = { enable = true },
                hover = { enable = true },
                completions = { enable = true },
                rename = { enable = true },
                codeActions = { enable = true },
                selectionRange = { enable = true },
                documentHighlight = { enable = true },
                runesLegacyModeCodeLens = { enable = true },
                defaultScriptLanguage = "none",
              },
            },
          },
        },
      })

      -- Activation des serveurs installés via Mason
      -- Tu peux activer manuellement les serveurs que tu veux
      vim.lsp.enable({
        'eslint',
        'vtsls',
        'clangd',
        'gopls',
        'bashls',
        'cssls',
        'tailwindcss',
        'svelte',
        'taplo',
        'lua_ls',
      })
    end,

    -- golang
    vim.lsp.config('gopls', {
      settings = {
        gopls = {
          hints = {
            parameterNames = true,
            assignVariableTypes = true,
            compositeLiteralFields = true,
            compositeLiteralTypes = true,
            constantValues = true,
            functionTypeParameters = true,
            rangeVariableTypes = true,
          },
        },
      },
    })
  },
}
