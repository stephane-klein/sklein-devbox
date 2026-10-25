# sklein-devbox-mise-config

Machine setup for the `sklein-devbox-dev` system container (LXC), applied with
[Mise Bootstrap](https://mise.jdx.dev/bootstrap.html).

## Two mise configs, two scopes

This directory deliberately holds two mise configurations. They do not play the
same role, and confusing them is the main pitfall.

| File in the container | Source here | Loaded when | Purpose |
| --- | --- | --- | --- |
| `~/.local/share/sklein-devbox/sklein-devbox-mise-config/mise.toml` | `mise.toml` | only when the working directory is `~/.local/share/sklein-devbox/sklein-devbox-mise-config/` (or with `mise -C` / `--cd`) | **Bootstrap driver**: `[bootstrap.*]`, `[dotfile_groups.*]`, `[dotfiles]`, `[settings]`, and the tools needed during bootstrap |
| `~/.config/mise/config.toml` | `dotfiles/dot-config/mise/config.toml` | everywhere | **Global config**: user-wide `[settings]`, `[tools]` and `[shell_alias]` |


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

It must **not** contain `[bootstrap.*]`, `[dotfiles]` or `[dotfile_groups.*]`. Its
source is `dotfiles/dot-config/mise/config.toml`, deployed by the driver's
`[dotfile_groups.home]` tree (a `copy` walk with `dot_prefix`, which maps
`dot-config/…` to `~/.config/…`).

`mise use -g` and `mise settings set` write this file. The home group uses
`dot_prefix`, and `mise dot add` refuses to capture into such an entry, so edit
the source directly (`dotfiles/dot-config/mise/config.toml`), or use
`mise use --path dotfiles/dot-config/mise/config.toml …` from the driver
directory.

## Shell aliases

The global config defines shortcuts so you never have to type the driver path:

```toml
[shell_alias]
devbox-cd        = "cd \"$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config\""
devbox-dot       = "mise -C \"$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config\" run dot"
devbox-bootstrap = "mise -C \"$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config\" run bootstrap-all"
```

`mise activate` sets these aliases in interactive bash/zsh/fish shells. They are
**not** available in tasks, scripts, or `mise exec`. `devbox-cd` changes the
current shell's directory; `devbox-dot apply` is shorthand for
`mise -C ~/.local/share/sklein-devbox/sklein-devbox-mise-config run dot apply`,
which in turn runs the dotfiles under `fnox exec` (see
[Bootstrap secrets and fnox](#bootstrap-secrets-and-fnox)).

`devbox-bootstrap` is shorthand for `mise run bootstrap-all` and converges the
whole instance — `[bootstrap.packages]`, `[bootstrap.files]`, services, then the
dotfiles and `[tools]`. Use it whenever a change touches any `[bootstrap.*]`
section: `devbox-dot apply` applies only the `[dotfiles]` entries (and installs
`[tools]`), never `[bootstrap.packages]`.

## Shell completions

`dotfiles/dot-zshrc` wires four completion sources, in this order:

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
`dotfiles/dot-config/mise/config.toml` takes effect without a manual
`mise install`.

## Remote-desktop link

The foot host gives the headless instance access to its desktop (open URLs,
notifications, audio) over two reverse-unix-socket ssh forwards that the
`sklein-devbox console` subcommand sets up as a per-instance systemd **user**
unit on the foot host (`sklein-devbox-foot-link-<instance>.service`, one
dedicated `ssh -N`). The same link can be created, repaired or restarted for
every running instance without opening foot with `sklein-devbox foot-link`. It
is adapted from
[stephane-klein/foot-incus-ssh-tmux-osc52-poc](https://github.com/stephane-klein/foot-incus-ssh-tmux-osc52-poc)
(`docs/remote-desktop-link.md`).

This repository provides the **instance side** of the link:

- `[bootstrap.packages]` — `libnotify` (`notify-send`) and `pulseaudio-utils`
  (`paplay`, `pactl`).
- `files/xdg-open` and `files/notify-send` deployed to `/usr/local/bin/` — the
  system tools fail on the headless instance; these wrappers reach the foot
  host's desktop portal (`org.freedesktop.portal.OpenURI`) and notification
  daemon over the forwarded session bus, setting `DBUS_SESSION_BUS_ADDRESS` for
  that invocation only.
- `files/ssh-tmux-login` — exports `PULSE_SERVER` **only when**
  `/tmp/foot-host-pulse` exists (so a missing carrier does not leave the
  variable dangling), and mirrors it into the tmux server/session environment
  (the wrapper's own environment only seeds the tmux server at its creation, and
  `update-environment` does not list it). It deliberately does **not** export
  `DBUS_SESSION_BUS_ADDRESS`: podman reads it to locate the systemd user bus for
  its sandbox cgroup, and a foreign (host) bus makes `podman run` / `podman
  compose` fail with `Failed to add podman to systemd sandbox cgroup ...
  No such process`. The host bus is set per tool instead (above).
- `files/sshd-foot-link.conf` (`StreamLocalBindUnlink yes`) — lets a restarted
  carrier re-bind the reverse socket over a stale one.
- `files/sshd-tmux-force.conf` — besides the `ForceCommand`, sets
  `ClientAliveInterval 30` / `ClientAliveCountMax 3` under `Match User devbox`:
  a vanished client (workstation suspended, network loss) is detected in ~90 s
  instead of waiting for the TCP retransmissions, which detaches its
  `console-*` tmux session so the next `ssh-tmux-login` reaps it.

## Instance doctor

`dotfiles/bin/sklein-devbox-doctor` is deployed to `~/bin/sklein-devbox-doctor`
(that directory is not on `PATH`, so invoke it by path). Run it from a console
inside the instance to exercise the instance side of the link end to end:

- it first runs `mise doctor`;
- then it walks through the link capabilities, asking after each whether you
  perceived the effect — a desktop notification (`notify-send`), a sound
  (`paplay`, default `~/.local/share/sklein-devbox/sounds/door-bell.ogg`) and a
  URL (`xdg-open`).

A transport failure (missing socket, unreachable bus) is reported separately
from a perception failure, and the exit status is non-zero when a check fails.
When both `/tmp/foot-host-bus` and `/tmp/foot-host-pulse` are missing it exits 2
and points at `sklein-devbox foot-link` to run on the foot host. The default
sound is CC0; see `files/sounds/README.md`.

## GPG signing doctor

`dotfiles/bin/gpg-signing-doctor` is deployed to `~/bin/gpg-signing-doctor`.
It checks the signing chain used by git and jj: gpg, gpg-agent,
`~/bin/pinentry-tmux` and the tmux popup. Run it from a console inside the
instance:

```sh
~/bin/gpg-signing-doctor
```

- **inventory**: `pinentry-program`, agent, `GPG_TTY`, popup client, signing
  key, keygrip and whether the passphrase is cached;
- **automated**: with a fake `tmux`, no attached client must fail at once with
  `No pinentry`, and a popup that cannot open must give up with
  `Operation cancelled`; a stub pinentry checks the popup relay round-trip;
  then it asserts that no FIFO, log or process is left behind;
- **guided** (`--only-sign`, interactive): creates a throwaway key in a
  temporary `GNUPGHOME`, prints a disposable passphrase, and asks you to type
  it in the real popup, then verifies the signature. Your own key, its 24 h
  cache and the real agent are never touched.

Useful options: `--only-config`, `--only-fallback`, `--only-timeout`,
`--only-relay`, `--only-sign`, `--key KEY`. `sklein-devbox-doctor --with-gpg`
runs it in the same pass and aggregates its result; `sklein-devbox-doctor
--only-gpg` delegates to it entirely.



## Updating the global tools

`dotfiles/bin/sklein-devbox-mise-upgrade` is deployed to
`~/bin/sklein-devbox-mise-upgrade`. It walks `mise outdated --bump`, asks tool
by tool whether to take the bump, writes the accepted versions into the driver
**source** (`dotfiles/dot-config/mise/config.toml`) with `mise use --path`, then
runs the fnox-wrapped `mise -C <driver> run dot apply` so the change lands in
`~/.config/mise/config.toml` and the tools are installed:

```sh
~/bin/sklein-devbox-mise-upgrade
```

Options: `-n`/`--dry-run` (list the bumps, change nothing), `-y`/`--yes` (take
every bump without prompting), `--no-apply` (update the config but skip
`dot apply`), `--driver DIR`.

Only tools sourced from `~/.config/mise/config.toml` are considered; tools
declared in another config file are listed and skipped. The script never edits
the deployed `~/.config/mise/config.toml` directly: it writes the driver source,
which mutagen syncs back to the workstation. In git-bootstrapped mode (no
mutagen) the edit stays in the container clone and must be committed from the
workstation to persist.

## Wildcard subdomains (`sklein-devbox-ingress`)

`dotfiles/bin/sklein-devbox-ingress` is deployed to `~/bin/sklein-devbox-ingress`
(that directory is not on `PATH`, so invoke it by path). It exposes the instance
to the NetBird network under `*.<tld>` and terminates TLS for the daemons behind
a per-hostname certificate. `<tld>` is the **host's own FQDN** (`hostname -f`,
e.g. `sklein-devbox-dev.homelab.stephane-klein.info`): the script and the
pitchfork proxy template both derive it the same way, so they cannot diverge.

```sh
~/bin/sklein-devbox-ingress up       # NetBird zone + wildcard record + proxy
~/bin/sklein-devbox-ingress status   # proxy, zone, record, NetBird resolution
~/bin/sklein-devbox-ingress down [--purge]
```

`down` removes the wildcard record (peers stop resolving the ingress);
`--purge` also deletes the zone and the legacy nameserver group.

It ties two pieces together, none of which needs cloud-init or a root systemd
unit:

- a **NetBird Custom DNS Zone** whose domain is `<tld>`, distributed to the
  `All` group, holding one wildcard `A` record `*.<tld>` → the `wt0` address.
  NetBird serves it from its own resolver on every peer. No DNS daemon runs on
  the instance, and `up` must run after `netbird up` (the record carries the
  overlay address).
- the **pitchfork reverse proxy** (`[settings.proxy]` in
  `dotfiles/dot-config/pitchfork/config.toml.tera`): `tld` = the host FQDN,
  `host = "0.0.0.0"` (so peers reach the dynamic `wt0` address) and `port = 443`.
  It signs a certificate per requested hostname from its local CA
  (`~/.local/state/pitchfork/proxy/ca.pem`), which clients must trust —
  distribute it and run `pitchfork proxy trust --cert <copied-ca.pem>`.

The only privileged step is `pitchfork proxy setup` (bind capability for
`:443`, CA trust into the system store), run by `up` and re-run after a
pitchfork upgrade. Everything else runs as `devbox`.

### Why a zone and not a nameserver

`<tld>` is a peer FQDN, i.e. a name inside the NetBird peer DNS domain
(Settings → Network → DNS Domain, here `homelab.stephane-klein.info`). The
NetBird client resolver is **authoritative** for that domain: it answers peer
names and returns NXDOMAIN with the `aa` flag for everything else, never
forwarding to a nameserver. A nameserver group with `match domain = <tld>`
would look `Available` in `netbird status -d` and still be dead config. Zone
records are injected into that authoritative answer instead — the only
supported way to add names under the peer DNS domain (same mechanism as
`*.sklein.internal`).

### One label level only

A wildcard record matches exactly one label, so:

- `<slug>.<tld>` resolves — this covers global daemons routed with `[slugs]`;
- `<daemon>.<project>.<tld>` and `<extra>.<slug>.<tld>` do **not** resolve.
  The proxy would route them, but no peer can resolve the name.

Getting more levels would require moving the TLD out of the peer DNS domain
(e.g. a dedicated zone like `devbox.sklein.dev`), since NetBird never delegates
a subdomain of its own peer domain.

### Checking it

`status` queries the zone and the record through the API, then asks **this
peer's NetBird resolver** (`dig @<wt0 ip>`) — which answers the zone records
exactly like any other peer. Do not trust a local `getent`/`dig` without
`@<wt0 ip>`: `pitchfork proxy setup` installs a stub on `127.0.0.1:15353` that
answers `*.<tld>` with `127.0.0.1` on the ingress host itself, so the system
resolver always looks green there.

Connected peers pick the zone up on their next network map update; if a name
still does not resolve, resync the client: `netbird down && netbird up`.

Daemons defined in the global pitchfork config get no project hostname; route
them through the proxy with a `[slugs]` entry (see the commented block in
`config.toml.tera`). To expose a service, set a daemon's `port`, add a slug,
and it answers at `<slug>.<tld>`.

## Rules of thumb

- Global tools go in `dotfiles/dot-config/mise/config.toml`, never in the driver.
- The driver keeps only what bootstrap itself needs.
- `dotfiles.root` stays in the driver (relative path resolution).
- `mise dot` and `mise bootstrap` need `[bootstrap.secrets]` in the environment:
  go through `mise run dot` / `mise run bootstrap-all` (or `fnox exec`) rather
  than a bare `mise dot` / `mise bootstrap`.
- `devbox-dot apply` (= `mise dot apply`) applies only the `[dotfiles]`; it never
  installs `[bootstrap.packages]`. Adding or changing a package means
  `devbox-bootstrap` (= `mise run bootstrap-all`), which also applies the
  dotfiles — `mise dot apply` is a phase of `mise bootstrap`.
- A `copy` entry overwrites its target on apply; replacing a real file with a
  `symlink` entry needs `mise bootstrap --force-dotfiles` (or `mise dot apply --force`).
- mise reads configs at process start: the driver's `post-dotfiles` hook runs
  `mise install` after every `mise dot apply`, so a `[tools]` change in the
  global config is installed in the same run. `status` and `diff` do not
  trigger it.
