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
mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config bootstrap --yes
```

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

### Global config — `~/.config/mise/config.toml`

Loaded for every `mise` invocation, in every directory. It contains only
user-wide content:

- `[tools]` — the global toolset
- `[shell_alias]` — interactive shortcuts available everywhere

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
devbox-dot = "mise -C \"$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config\" dot"
```

`mise activate` sets these aliases in interactive bash/zsh/fish shells. They are
**not** available in tasks, scripts, or `mise exec`. `devbox-cd` changes the
current shell's directory; `devbox-dot apply` is shorthand for
`mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config dot apply`.

## Applying dotfiles

The `[dotfiles]` entries live in the project-scoped driver, so mise only sees
them when the working directory is this one (or with `-C`). From inside the
container:

```sh
devbox-cd                      # cd into the driver
mise dot status
mise dot diff ~/.config/atuin
mise dot apply
```

or, without changing directory:

```sh
devbox-dot status
devbox-dot diff ~/.config/atuin
devbox-dot apply
```

Falling back to the explicit form always works:

```sh
mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config dot apply
```

## Rules of thumb

- Global tools go in `dotfiles/.config/mise/config.toml`, never in the driver.
- The driver keeps only what bootstrap itself needs.
- `dotfiles.root` stays in the driver (relative path resolution).
- A `copy` entry overwrites its target on apply; replacing a real file with a
  `symlink` entry needs `mise bootstrap --force-dotfiles` (or `mise dot apply --force`).
- mise reads configs at process start: a config written during the `dotfiles`
  phase is not re-read in the same run. Run `mise install` again if a change to
  the global tools must take effect immediately.
