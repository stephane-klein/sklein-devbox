# Agent Instructions

This is the Neovim configuration of Stéphane Klein, based on
[LazyVim](https://lazyvim.org) and managed with
[ChezMoi](https://chezmoi.io). The source code is published at:
<https://github.com/stephane-klein/sklein-devbox-chezmoi/tree/main/dot_config/nvim>

### Why not the LazyVim extra (`lang.svelte`)?

The LazyVim `lang.svelte` extra was rejected in favor of a manual setup for
these reasons:

1. **LSP setup pattern mismatch** — This config uses the native Neovim 0.11
   `vim.lsp.enable()` API, while the extra uses `opts.servers`. Combining
   both would risk duplicate or conflicting server configuration.
2. **TypeScript variant mismatch** — This config uses the `typescript.biome`
   extra rather than the standard `typescript` extra that `lang.svelte`
   depends on.
3. **Redundant scope** — The extra also manages treesitter and Prettier for
   Svelte, which are already handled elsewhere.
