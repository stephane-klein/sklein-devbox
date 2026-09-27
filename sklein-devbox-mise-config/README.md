# sklein-devbox-mise-config

Machine setup for the `sklein-devbox-dev` system container (LXC), applied with
[Mise Bootstrap](https://mise.jdx.dev/bootstrap.html).

## Two mise configs, two scopes

This directory deliberately holds two mise configurations. They do not play the
same role, and confusing them is the main pitfall.

| File in the container | Source here | Loaded when | Purpose |
| --- | --- | --- | --- |
| `~/.local/share/sklein-devbox/sklein-devbox-mise-config/mise.toml` | `mise.toml` | only when the working directory is `~/.local/share/sklein-devbox/sklein-devbox-mise-config/` (or with `mise -C` / `--cd`) | **Bootstrap driver**: `[bootstrap.*]`, `[dotfiles]`, `[settings]`, and the tools needed during bootstrap |
| `~/.config/mise/config.toml` | `dotfiles/.config/mise/config.toml` | everywhere | **Global config**: user-wide `[settings]`, `[tools]` and `[shell_alias]` |


### Bootstrap driver — `mise.toml`

Project-scoped config, and the entry point:

```sh
mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config run bootstrap-all
```

That task runs `fnox exec -- mise bootstrap --yes` (see
[Bootstrap secrets and fnox](#bootstrap-secrets-and-fnox)).

`-C` matters: without it mise never loads this file, so none of the
`[bootstrap.*]` or `[dotfiles]` entries are seen. For the same reason, `mise dot`
commands must be run with `-C ~/.local/share/sklein-devbox/sklein-devbox-mise-config`.

`dotfiles.root` and the relative `[dotfiles]` sources live **here**, because
relative paths in a config are resolved from that config file's directory. A
relative root in the global config would resolve against `~/.config/mise/`, not
against this directory.

`[settings]` here also disables mise's own git-backed dotfile history
(`history.enabled = false`): this repository is the source of truth, so the
history store and the watcher are unused and `mise dot status` omits the
history/setup-repository hints.

### Bootstrap secrets and fnox

The driver declares `[bootstrap.secrets]` (`SSH_ID_RSA_2016_PRIVATE`,
`MISE_CI_READONLY_GITHUB_TOKEN`, `OPENCHAMBER_UI_PASSWORD`,
`INCUS_PRIVATE_CLIENT_CRT`, `INCUS_PRIVATE_CLIENT_KEY`,
`HOMELAB_STEPHANE_KLEIN_INFO_K3S_KUBECONFIG`). mise only reads those
values from the environment; the provider is [fnox](https://fnox.jdx.dev),
backed by the gopass store. `mise dot` and `mise bootstrap` must therefore run
inside `fnox exec`, which exports the secrets for the duration of the command:

```sh
fnox -c ~/.local/share/sklein-devbox/sklein-devbox-mise-config/fnox.toml \
  exec -- mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config dot apply
```

Two driver tasks wrap this so callers never type it:

```sh
cd ~/.local/share/sklein-devbox/sklein-devbox-mise-config
mise run dot apply       # -> fnox exec -- mise dot apply
mise run bootstrap-all   # -> fnox exec -- mise bootstrap --yes
```

Both use `raw_args = true`, so subcommands, targets and flags pass through
verbatim: `mise run dot status`, `mise run dot diff ~/.config/atuin`,
`mise run dot apply --force`, `mise run bootstrap-all --dry-run`, ...

Without fnox (e.g. an attended one-off run), mise can prompt for the values
instead: `mise dot apply --prompt-secrets`.

### Global config — `~/.config/mise/config.toml`

Loaded for every `mise` invocation, in every directory. It contains only
user-wide content:

- `[tools]` — the global toolset
- `[shell_alias]` — interactive shortcuts available everywhere
- `[env]` — user-wide environment variables (e.g. `KUBECONFIG`, see
  [Kubernetes access](#kubernetes-access))

It must **not** contain `[bootstrap.*]` or `[dotfiles]`. Its source is
`dotfiles/.config/mise/config.toml`, installed by a `[dotfiles]` entry declared
in the driver.

`mise use -g` and `mise settings set` write this file. In `copy` mode, capture
the changes back into the source with `mise dot add ~/.config/mise/config.toml`
(run it from the driver directory, or with `mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config`).

## Shell aliases

The global config defines shortcuts so you never have to type the driver path:

```toml
[shell_alias]
devbox-cd  = "cd \"$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config\""
devbox-dot = "mise -C \"$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config\" run dot"
```

`mise activate` sets these aliases in interactive bash/zsh/fish shells. They are
**not** available in tasks, scripts, or `mise exec`. `devbox-cd` changes the
current shell's directory; `devbox-dot apply` is shorthand for
`mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config run dot apply`,
which in turn runs the dotfiles under `fnox exec` (see
[Bootstrap secrets and fnox](#bootstrap-secrets-and-fnox)).

## Shell completions

`dotfiles/.zshrc` wires four completion sources, in this order:

- **mise** — `eval "$(mise completion zsh)"`. `mise activate` only wires completions for managed tools that ship one (fnox, pitchfork, ...), never for the `mise` command itself, which needs its own line.
- **carapace** — the multi-command completion engine (`carapace` in the global `[tools]`). A single `source <(carapace _carapace)` dispatches to per-command completers, so no per-tool script is needed. Supported completers: <https://carapace-sh.github.io/carapace-bin/completers.html>
- **gopass** — native `source <(gopass completion zsh)` (carapace has no gopass completer).
- **fzf-tab** — turns zsh's completion menu into an fzf picker. The plugin is vendored into `~/.config/zsh/fzf-tab` by `scripts/sync-fzf-tab.sh` (not committed; fetched by the driver's `pre-dotfiles` hook, refresh with `mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config run update-fzf-tab`).

## Applying dotfiles

The `[dotfiles]` entries live in the project-scoped driver, so mise only sees
them when the working directory is this one (or with `-C`). From inside the
container:

```sh
devbox-cd                      # cd into the driver
mise run dot status
mise run dot diff ~/.config/atuin
mise run dot apply
```

or, without changing directory:

```sh
devbox-dot status
devbox-dot diff ~/.config/atuin
devbox-dot apply
```

Falling back to the explicit form always works (the fnox wrapper supplies the
bootstrap secrets):

```sh
fnox -c ~/.local/share/sklein-devbox/sklein-devbox-mise-config/fnox.toml \
  exec -- mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config dot apply
```

`mise dot apply` finishes by installing the tools of the freshly applied
global config. The driver declares a `post-dotfiles` bootstrap hook with
`run = "mise install"`; `mise dot apply` runs it (see
[hooks](https://mise.jdx.dev/bootstrap.html#hooks)), so a new entry in
`dotfiles/.config/mise/config.toml` takes effect without a manual
`mise install`.

## Rules of thumb

- Global tools go in `dotfiles/.config/mise/config.toml`, never in the driver.
- The driver keeps only what bootstrap itself needs.
- `dotfiles.root` stays in the driver (relative path resolution).
- `mise dot` and `mise bootstrap` need `[bootstrap.secrets]` in the environment:
  go through `mise run dot` / `mise run bootstrap-all` (or `fnox exec`) rather
  than a bare `mise dot` / `mise bootstrap`.
- A `copy` entry overwrites its target on apply; replacing a real file with a
  `symlink` entry needs `mise bootstrap --force-dotfiles` (or `mise dot apply --force`).
- mise reads configs at process start: the driver's `post-dotfiles` hook runs
  `mise install` after every `mise dot apply`, so a `[tools]` change in the
  global config is installed in the same run. `status` and `diff` do not
  trigger it.
