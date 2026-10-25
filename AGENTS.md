# AGENTS.md

## Where the configuration lives and how it runs

Many requests in this repo target the **running devbox container**, not the
workstation where this agent runs. Fixing a tool, a shell alias, tmux / starship
/ atuin / zsh behavior, reinstalling or upgrading a tool: the instance to inspect
is the container, reachable as:

    devbox@sklein-devbox-dev.homelab.stephane-klein.info

(Incus instance `sklein-devbox-dev`). Prefer inspecting the live container over
reasoning from the working tree alone.

You are expected to open SSH sessions and run commands inside the container,
including state-changing ones (`mise dot apply`, `mise install`, restarting a
service, editing a deployed file to reproduce a bug). It is a throwaway POC. When
a task is about current behavior, SSH and look instead of assuming.

The container's configuration is the **deployed** form of this repo's
`sklein-devbox-mise-config/` directory.

| | Workstation (here) | Container (live) |
| --- | --- | --- |
| mise driver (project-scoped) | `sklein-devbox-mise-config/mise.toml` | `~/.local/share/sklein-devbox/sklein-devbox-mise-config/mise.toml` |
| mise global config | `sklein-devbox-mise-config/dotfiles/.config/mise/config.toml` | `~/.config/mise/config.toml` |
| other dotfiles | `sklein-devbox-mise-config/dotfiles/.config/…` | `~/.config/…` |
| gopass store | `~/.local/share/gopass/stores/root/` | `~/.local/share/gopass/stores/root/` |

## Accessing the container

- `mise run ssh` — plain SSH session as `devbox`.
- `ssh devbox@sklein-devbox-dev.homelab.stephane-klein.info` — same, directly.
- `mise run console` — `incus exec sklein-devbox-dev -- bash` (bypasses SSH).

## Inspecting the live configuration

- The files under `~/.config/` in the container are **copies** produced by
  `mise dot apply`, not symlinks into the repo. Read them to see what is
  actually in effect.
- The repo `sklein-devbox-mise-config/` is the source of truth; its own
  `README.md` explains the driver/global split in detail.

## Editing and applying

- Edit the source under `sklein-devbox-mise-config/` in this repo. Never edit the
  deployed copy in the container: `mise dot apply` overwrites `~/.config/*` on
  the next run and your change is lost.

### Workstation-synced mode (mutagen, development)

- mutagen keeps `./sklein-devbox-mise-config/` in **two-way sync** with
  `~/.local/share/sklein-devbox/sklein-devbox-mise-config/` in the container.
  Edit here; the sync propagates. Pause/resume with
  `mise run mutagen-stop` / `mise run mutagen-start`.
- Then apply the dotfiles **inside the container**:

      mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config run dot apply

  The driver tasks `mise run dot` / `mise run bootstrap-all` wrap `fnox exec`,
  which supplies the `[bootstrap.secrets]` values. A bare `mise ... dot apply`
  fails without those secrets in the environment; the explicit fallback is
  `fnox -c <driver>/fnox.toml exec -- mise -C <driver> dot apply`.

- In an interactive shell the aliases `devbox-cd` and
  `devbox-dot status|diff|apply` do the same (`devbox-dot` maps to
  `mise -C <driver> run dot`). They come from `mise activate` and are **not**
  available in tasks, scripts, or `mise exec`; use `mise -C <driver> run dot …`
  there.

### Git-bootstrapped mode (production, no mutagen)

- mutagen is disabled: the container's git working tree at
  `~/.local/share/sklein-devbox/` is the source of truth. To change the config,
  commit/push the branch and recreate the container
  (`mise run incus-start-lxc-with-bootstrap`); the in-container clone is the one
  that matters.

## Pitfalls

- The driver `mise.toml` must be invoked with `-C <driver dir>`; without it mise
  never loads `[bootstrap.*]` or `[dotfiles]`. The global config
  (`~/.config/mise/config.toml`) must contain neither of those.
- `mise use -g` / `mise settings set` write the global config inside the
  container. Capture the change back into the repo with
  `mise dot add ~/.config/mise/config.toml` run from the driver directory.
- `mise dot apply` ends by running the driver's `post-dotfiles` hook
  (`mise install`), so a `[tools]` change is installed in the same run; `status`
  and `diff` do not trigger it.
- A `copy` dotfile entry overwrites its target; switching it to `symlink`
  requires `mise bootstrap --force-dotfiles` (or `mise dot apply --force`).
- `mise dot` and `mise bootstrap` resolve `[bootstrap.secrets]` from the
  environment; run them through the driver tasks `mise -C <driver> run dot` /
  `mise -C <driver> run bootstrap-all` (or `fnox exec`) rather than bare
  `mise dot` / `mise bootstrap`.
- GPG signing (git, jj) prompts through the vendored `~/bin/pinentry-tmux`,
  which opens a `tmux display-popup` on the client attached to the session
  owning `GPG_TTY`. Without an attached tmux client it fails immediately with
  `No pinentry`; it never falls back to a tty pinentry, which would corrupt
  the screen of Neovim or OpenCode. gpg-agent caches the passphrase for 24 h,
  so a broken prompt may only show up after a reboot or cache expiry. Upstream
  is unmaintained (last commit nov. 2022); a rewrite is being evaluated at
  https://github.com/mmmeon/pit. `~/bin/gpg-signing-doctor` checks the whole
  chain without touching your key or its cache (`--with-gpg` from
  `~/bin/sklein-devbox-doctor`).

## OpenCode 2 server topology

- The OpenCode server is supervised by pitchfork as a foreground process:
  `opencode serve --service`. Service mode binds port 4096 and registers itself
  in `~/.local/state/opencode/service.json` (URL + password); every client — TUI,
  CLI subcommands, OpenChamber — discovers it, so no `--server` flag and no
  password environment variable are needed. Note that `--server` is a
  per-subcommand flag in V2, not a global one: `opencode --server … auth list`
  fails, `opencode auth list --server …` works.
- Port, hostname and password are pinned by the bootstrap `post-dotfiles` hook
  (`opencode service set port 4096`, `hostname 127.0.0.1`, `password`), the
  password coming from gopass `opencode/devbox/server-password`. Do not disable
  the service: clients would silently start private servers on the same
  `opencode.db`.
- Provider credentials live in the SQLite database. `~/.local/share/opencode/credentials.json`
  (rendered from gopass) seeds them on a fresh instance through
  `opencode auth import --standalone` in the bootstrap hook: two OpenCode Go
  accounts (`account1` active, `account2` inactive) plus the fixed deepseek and
  openrouter keys. Switch accounts from the TUI (`/connect`) or OpenChamber
  (Settings → Providers); `opencode auth switch <integration> <label>` is only
  for scripts. `auth.json` is no longer used.
- Plugins are server-side (`plugins` in `~/.config/opencode/opencode.jsonc`);
  TUI-only settings live in `~/.config/opencode/cli.json`. `tui.json` is gone.
- `mise dot apply` ends with `pitchfork restart global/opencode-server`, because
  the running process keeps the old binary, plugin modules and daemon
  environment. The apply therefore kills running OpenCode sessions: run it from
  a plain SSH shell, never from an OpenCode tool call. Configuration files under
  `~/.config/opencode` are hot-reloaded by the server and need no restart; a TUI
  plugin change only requires reopening the TUI.

## If you are already inside the container

opencode is installed in the container too. In that case the driver directory is
`~/.local/share/sklein-devbox/sklein-devbox-mise-config/` (no SSH needed) and the
edit/apply rules above are unchanged.
