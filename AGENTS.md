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
- GPG signing (git, jj) prompts through the vendored
  `~/.local/libexec/sklein-devbox/pinentry-tmux`, which opens a `tmux
  display-popup` on the client attached to the session
  owning `GPG_TTY`. Without an attached tmux client it fails immediately with
  `No pinentry`; it never falls back to a tty pinentry, which would corrupt
  the screen of Neovim or OpenCode. With several clients attached — two SSH
  terminals on the same instance, for example, which are grouped sessions
  sharing the same panes — the popup opens on the client that received input
  last, so look at the terminal you just typed in: a popup in the other one
  looks like a hang. gpg-agent caches the passphrase for 24 h,
  so a broken prompt may only show up after a reboot or cache expiry. Upstream
  is unmaintained (last commit nov. 2022); a rewrite is being evaluated at
  https://github.com/mmmeon/pit. `~/bin/gpg-signing-doctor` checks the whole
  chain without touching your key or its cache (`--with-gpg` from
  `~/bin/sklein-devbox-doctor`).

## OpenCode 2 server topology

- `opencode-server` is the pitchfork `boot_start` daemon that runs
  `opencode serve --service`. Every client — TUI, CLI subcommands, scripts,
  OpenChamber — discovers it through
  `~/.local/state/opencode/service.json` (URL + password), so no `--server`
  flag and no password environment variable are needed. `--service` takes
  OpenCode's single-writer lease: a second `--service` server on the machine
  displaces the first, so never start one by hand. Note that `--server` is a
  per-subcommand flag in V2, not a global one: `opencode --server … auth list`
  fails, `opencode auth list --server …` works.
- OpenChamber connects to that server through its `useGlobalOpenCodeService`
  setting, stored in `~/.config/openchamber/settings.json` and shipped by a
  `merge` dotfile entry. It does not launch a child of its own. Its agent tools
  come from the OpenChamber plugin listed in
  `~/.config/opencode/opencode.jsonc` (`plugins`), not from the server's
  environment: the plugin reads `~/.config/openchamber/runtime-bridge.json` and
  stays dormant while OpenChamber is down. This is why adding the plugin from
  the UI is not enough; the dotfile template must carry it, otherwise the next
  `mise dot apply` removes it.
- `sklein-devbox-doctor` checks that `opencode-server` runs with `--service`,
  that `service.json` names its pid, version and a password that authenticates,
  and that OpenChamber's shared-service setting and the plugin are in place.
- Port, hostname and password are pinned by the bootstrap `post-dotfiles` hook
  (`opencode service set port 4096`, `hostname 127.0.0.1`, `password`), the
  password coming from gopass `opencode/devbox/server-password`. The server
  reads it from `~/.config/opencode/service.json` and publishes it in
  `service.json`. Do not set `disabled true` to stop clients from
  starting a server on port 4096: that flag does not block a server, it makes
  every client behave like `--standalone`. Each client then runs its own private
  server on an ephemeral port and stops using the shared one, while OpenChamber
  keeps talking to 4096: several servers on the same `opencode.db`. Keep the key
  at `false`; `set disabled false` does not stop a running service, only `true`
  does.
- The pitchfork supervisor belongs to systemd: a user unit created by
  `pitchfork boot enable` runs `supervisor run --boot`, the only mode that
  starts the daemons marked `boot_start`. The `post-dotfiles` hook also enables
  linger (`loginctl enable-linger "$USER"`), so the unit starts at boot without
  a login. A manual `pitchfork supervisor start --force` is not boot mode: it
  stops every daemon and leaves them down, which is how OpenChamber and the
  OpenCode server stayed off after the 2026-10-28 reload and let a client take
  port 4096. Reload with `systemctl --user restart pitchfork`;
  `~/bin/sklein-devbox-ingress up` does exactly that.
- A supervisor outside the unit shows up as `502 No daemon found for host` on
  every ingress URL, not as a dead port: the proxy runs, the `boot_start`
  daemons do not. The `30-restart.conf` drop-in sets `Restart=always`, so the
  unit replaces a supervisor killed from outside (a manual `--force`, or the
  on-demand start that any pitchfork command triggers), and the
  `post-dotfiles` hook hands one it finds beside an inactive unit over to
  systemd. Stop the supervisor for good with `systemctl --user stop pitchfork`,
  never with `pitchfork supervisor stop`, which systemd now undoes.
  `~/bin/sklein-devbox-doctor` reports a supervisor whose pid is not the unit's
  `MainPID`, an inactive unit, and an active unit without a `:443` listener.
- `opencode-server` declares `ready_port = 4096`, not `port`, and its run script
  starts with `opencode-port-free`. The script stops an unsupervised `opencode`
  process holding port 4096 before the server is exec'd, so a client-started
  server cannot block the daemon, at boot included (it did on 2026-11-22, before
  this switch). `port` makes pitchfork check availability before it starts the
  daemon; `ready_port` only waits for the listener.
- `opencode-server` carries `NODE_OPTIONS=--use-openssl-ca` and a PATH that
  contains `~/.local/bin`. Without them the SearXNG MCP server and `webfetch`
  fail on the homelab CA, and MCP servers declared as `mise exec -- …` fail
  with `NotFound: ChildProcess.spawn`.
- Provider credentials live in the SQLite database. `~/.local/share/opencode/credentials.json`
  (rendered from gopass) is the source of truth: `~/bin/import-opencode-credentials`
  runs at the end of the bootstrap hook and logs the managed accounts out,
  reimports the file and restores the account that was active (`auth import`
  alone is a one-shot seed, it skips ids it already knows and therefore never
  picks up a rotated key). It holds two OpenCode Go accounts (`account1`,
  `account2`) plus the fixed deepseek and openrouter keys. Switch accounts from
  the TUI (`/connect`) or OpenChamber (Settings → Providers) — the choice holds
  until the next apply; `opencode auth switch <integration> <label>` is for
  scripts. `auth.json` is no longer used.
- Plugins are server-side (`plugins` in `~/.config/opencode/opencode.jsonc`);
  TUI-only settings live in `~/.config/opencode/cli.json`. `tui.json` is gone.
- `mise dot apply` ends with `systemctl --user restart pitchfork`, because the
  supervisor and the daemons keep the binary, plugin modules and environment
  they started with. The hook re-runs `pitchfork proxy setup --yes` first when
  the capability check fails: `mise install` replaces the binary and the inode
  loses `cap_net_bind_service`, so a restarted supervisor would fail to bind
  `:443` and every ingress URL would stop answering. The check and the `proxy
  setup` / `boot enable` calls use the binary of `settings.boot.executable`,
  the one the unit runs, not the versioned pitchfork of the invoking shell.
  After the restart the hook waits for the `:443` listener and retries the setup
  once. The apply therefore kills running OpenCode sessions: run it from a
  plain SSH shell, never from an OpenCode tool call. Configuration files under
  `~/.config/opencode` are hot-reloaded by the server and need no restart; a TUI
  plugin change only requires reopening the TUI.

## If you are already inside the container

opencode is installed in the container too. In that case the driver directory is
`~/.local/share/sklein-devbox/sklein-devbox-mise-config/` (no SSH needed) and the
edit/apply rules above are unchanged.
