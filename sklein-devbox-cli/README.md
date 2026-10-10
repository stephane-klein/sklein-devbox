# sklein-devbox-cli

The `sklein-devbox` command-line interface: a single, self-contained bash
script that launches and drives the Incus-based development environment.

The script has no build step. Installation needs `bash` and `curl`; `console`
needs `foot` and `ssh`, and optionally `mosh`; `up` additionally needs `incus`,
`ssh-keygen`, `ssh-keyscan` and `getent` (plus `gopass` when
`NETBIRD_SETUP_KEY` is not already exported). Reading a configuration file
additionally needs `yq` (mikefarah v4).

## Install

```sh
$ curl -fsSL https://raw.githubusercontent.com/stephane-klein/sklein-devbox/poc-reboot-to-incus-lxc-and-mise-bootstrap/sklein-devbox-cli/install.sh | bash
```

The installer downloads the script, stamps it with the resolved git sha,
installs it in `~/.local/bin`, and drops `foot.ini` in
`~/.config/sklein-devbox/`.

### Install under a different name

To keep a development build from clashing with an existing install, set
`SKLEIN_DEVBOX_EXEC_NAME`. The variable must be set on `bash`, not on `curl`:

```sh
$ curl -fsSL https://raw.githubusercontent.com/stephane-klein/sklein-devbox/poc-reboot-to-incus-lxc-and-mise-bootstrap/sklein-devbox-cli/install.sh | SKLEIN_DEVBOX_EXEC_NAME=sklein-devbox-poc bash
```

### Local install (development)

To install the working tree without going through `curl`, run the mise task:

```sh
$ mise run install-local          # from sklein-devbox-cli/
$ mise run install-local          # from the repository root (relay task)
```

It installs the CLI as `sklein-devbox-wip` in `~/.local/bin` and copies
`foot.ini` to `~/.config/sklein-devbox/`. The version is stamped with the local
short git sha.

## Usage

```sh
$ sklein-devbox --help
sklein-devbox launches a system development environment powered by Incus.

Usage:
  sklein-devbox [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  console     Open a tmux session in the devbox instance with a terminal emulator
  destroy     Destroy the sklein-devbox instance and all its data
  doctor      Check that the required commands are installed
  foot-link   Ensure the remote-desktop links (session bus + audio) to all instances
  help        Help about any command
  list        List all sklein-devbox instances
  logs        Show cloud-init and bootstrap logs of the instance
  resize      Resize the root disk of the sklein-devbox instance
  stop        Stop the sklein-devbox instance
  up          Start the sklein-devbox instance

Flags:
  -c, --config string  Configuration file (default: auto)
      --dry-run      Print commands without executing
  -h, --help         help for sklein-devbox
  -n, --name string  Instance name (default "dev1")
      --no-link      Do not manage the foot host -> instance reverse link
      --size string  Root disk size (default "250GiB")
      --terminal string  Terminal transport: ssh or mosh (default "ssh")
  -v, --version      version for sklein-devbox

Use "sklein-devbox [command] --help" for more information about a command.
```

### `completion`

Prints an autocompletion script for `bash`, `zsh` or `fish` (with dynamic
completion of instance names for `-n/--name`), or installs it in the standard
location for the detected shell:

```sh
$ source <(sklein-devbox completion zsh)
$ sklein-devbox completion bash > ~/.local/share/bash-completion/completions/sklein-devbox
$ sklein-devbox completion install          # detect shell and install
$ sklein-devbox completion install fish
```

`install` writes to `~/.local/share/bash-completion/completions/<name>` (bash),
`~/.zsh/completions/_<name>` (zsh, ensure it is in `fpath`) or
`~/.config/fish/completions/<name>.fish` (fish). `install.sh` calls it
automatically after installing the binary.

### `console`

Opens a maximized [foot](https://codeberg.org/dnkl/foot) terminal running a
remote shell against the instance. The instance must exist and be running,
otherwise `console` fails with an explicit message.

The transport is selected with `--terminal` (or `SKLEIN_DEVBOX_TERMINAL`):

- `ssh` (default): `ssh -t` against the instance, equivalent to `mise run ssh`;
- `mosh`: `mosh` against the instance — opt-in. The ssh bootstrap reuses the
  same `StrictHostKeyChecking`, `UserKnownHostsFile` and `LogLevel` options, and
  mosh launches `env -u SSH_ORIGINAL_COMMAND /usr/local/bin/ssh-tmux-login`, so
  the shared tmux workspace is preserved.

  **Clipboard caveat**: mosh 1.4.0 only implements OSC 52 in the *write*
  direction, so it can never *read* the host clipboard — pasting from the host
  does not work (copying out of the instance does). `ssh` is required to read
  the host clipboard (and is the default); `console` prints a warning when mosh
  is selected.

  `SSH_ORIGINAL_COMMAND` must be cleared: `mosh-server` forwards it to the
  command it launches, and `ssh-tmux-login` (the sshd `ForceCommand`) uses it to
  decide between running a client command and starting tmux. Left set, it would
  contain the `mosh-server new …` line and the wrapper would re-launch
  `mosh-server` — detaching immediately — instead of starting tmux. The
  `--` before the host is required because the remote command contains `-u`,
  which mosh's own option parser would otherwise consume.

`mosh` is an **optional** dependency: the client only needs to be present where
the CLI runs (the `mosh-server` side is installed inside the instance). Forcing
`--terminal=mosh` without the client fails with an explicit message.

foot is invoked with `--log-level=error` to silence benign warnings (the
Wayland compositor and the COLRv1 emoji font). Override with
`SKLEIN_DEVBOX_FOOT_LOG_LEVEL=warning` (or `info`) to see them again.

Before opening foot, `console` ensures a dedicated **remote-desktop link**: a
per-instance [systemd](https://systemd.io) **user** unit
(`sklein-devbox-foot-link-<instance>.service`) running an `ssh -N` that
reverse-forwards the foot host's session bus and audio server into the instance
as the unix sockets `/tmp/foot-host-bus` and `/tmp/foot-host-pulse`.
`ssh-tmux-login` exports them, so `notify-send`, `xdg-open` and `paplay` in the
instance reach the local desktop. The unit is `enable`d and restarted only when
its content changes (opening a second console does not flap it); it is stopped
by `stop` and removed by `destroy`. Orphan units (instance deleted by other
means) are pruned by `console` and `doctor`. Disable with `--no-link` or
`SKLEIN_DEVBOX_FOOT_LINK=0`; a missing systemd user manager is a non-fatal
warning. The same link can be created, repaired or restarted on its own with
`foot-link`.

```sh
$ sklein-devbox console
$ sklein-devbox console --terminal=mosh
$ sklein-devbox --no-link console
$ sklein-devbox --name dev2 console
$ sklein-devbox --dry-run console
```

### `foot-link`

Ensures the remote-desktop link (the `ssh -N` reverse-forwarding the foot host
session bus and audio server into the instance) for **every running**
`sklein-devbox-*` instance: creates, repairs or restarts each per-instance
systemd **user** unit, **without opening foot**. Stopped instances are skipped
and `--name` is ignored. A disabled link (`--no-link` /
`SKLEIN_DEVBOX_FOOT_LINK=0`) or a missing systemd user manager fails with an
explicit message. The exit status is non-zero when at least one running
instance's link did not come up.

```sh
$ sklein-devbox foot-link
sklein-devbox-dev: link up
sklein-devbox-dev2: link up
sklein-devbox-dev3: skipped (instance is STOPPED)
```

### `doctor`

Checks that the required commands (`foot`, `incus`, `ssh`) and the `up`
requirements (`incus`, `ssh-keygen`, `ssh-keyscan`, `getent`) are installed,
then reports the optional commands (`mosh`) and the resolved configuration.
Exits non-zero when a required command is missing; a missing optional command
does not affect the exit status.

```sh
$ sklein-devbox doctor
==> Required commands
  ok    foot   /usr/bin/foot
  ok    incus  /usr/bin/incus
  ok    ssh    /usr/bin/ssh

==> Up requirements
  ok    incus       /usr/bin/incus
  ok    ssh-keygen  /usr/bin/ssh-keygen
  ok    ssh-keyscan /usr/bin/ssh-keyscan
  ok    getent      /usr/bin/getent

==> Optional commands
  opt   mosh      not found (optional)
  ok    yq        /usr/bin/yq

==> Configuration
  version    dev
  instance   sklein-devbox-dev1
  fqdn       sklein-devbox-dev1.homelab.stephane-klein.info
  user       devbox
  terminal   ssh
  size       250GiB
  git-branch poc-reboot-to-incus-lxc-and-mise-bootstrap
  config     (none)
  foot.ini   /home/sklein/.config/sklein-devbox/foot.ini
  foot-log   error

==> Remote-desktop link
  systemd   available
  unit      sklein-devbox-foot-link-dev1
  path      /home/sklein/.config/systemd/user/sklein-devbox-foot-link-dev1.service
  state     active
  enabled   enabled
```

### `up`

Creates (if needed) and starts the instance, then bootstraps it from git.
Equivalent to `mise run incus-start-lxc-with-bootstrap`. The clone and the
Mise bootstrap always run (no toggle); mutagen is never used. New instances get
a `250GiB` thin root disk (`--size` / `SKLEIN_DEVBOX_DISK_SIZE`); an existing
instance is left untouched and must be grown explicitly with `resize`.

```sh
$ sklein-devbox up
$ sklein-devbox --name dev2 up
$ sklein-devbox --dry-run up
```

Missing secrets are requested interactively. Already-exported values are used
as-is:

| Variable | Input |
| --- | --- |
| `NETBIRD_PAT` | single line |
| `SSH_STEPHANE_KLEIN_DEVBOX` | multi-line, end with `Ctrl-D` |
| `SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_BASE64` | single line (base64) |
| `NETBIRD_SETUP_KEY` | from `gopass` if available, else multi-line `Ctrl-D` |
| `GOPASS_AGE_PASSWORD` | single line |

`up` walks through: image cache purge, `incus create` with the rendered
cloud-init, `incus start`, NetBird DNS wait, SSH host key refresh, then
`cloud-init status --wait`.

If cloud-init fails, `up` prints a diagnostic block: `cloud-init status
--long`, the warnings/errors from `/var/log/cloud-init.log`, the `runcmd`
script and the tail of `/var/log/cloud-init-output.log` — then suggests
`logs`.

With `--dry-run`, no command is executed, no secret is requested and the waits
are skipped. The rendered `cloud-init.user-data` is printed after the `incus
create` command, using the exported secrets when present and placeholders
(`<netbird-pat>`, `<ssh-private-key>`, …) otherwise — so real secrets appear in
clear text in the output if they are exported.

> [!IMPORTANT]
> `up` inlines the cloud-init template (`templates/cloud-init.yaml.jinja`), the
> devbox SSH config (`sklein-devbox-mise-config/dotfiles/.ssh/config`) and the
> logic of `scripts/incus-start-lxc.sh`. Any change there must be mirrored into
> `sklein-devbox`.

### `logs`

Prints the cloud-init state of the instance for post-mortem inspection:

```sh
$ sklein-devbox logs           # status --long, errors, runcmd, output tail
$ sklein-devbox logs output    # full /var/log/cloud-init-output.log
```

### `resize`

Grows the **root disk** of the instance by overriding its root device size.
The storage pool is an LVM **thin** pool, so the declared size is virtual: it
reserves no physical space — only written blocks are consumed. Growth happens
online, with no stop needed.

```sh
$ sklein-devbox resize                  # grow to 250GiB (default)
$ sklein-devbox resize --size 300GiB
$ sklein-devbox -n dev resize
$ sklein-devbox --dry-run resize
```

Shrinking is refused: the command exits non-zero if the target is smaller than
the current size. Use `--size` or `SKLEIN_DEVBOX_DISK_SIZE` to set the target.

### `list`

Lists every `sklein-devbox-*` instance with its state, creation date (local
time) and FQDN:

```sh
$ sklein-devbox list
NAME                 STATUS    CREATED           FQDN
sklein-devbox-dev    RUNNING   2026/09/26 21:48  sklein-devbox-dev.homelab.stephane-klein.info
sklein-devbox-dev2   RUNNING   2026/09/28 00:03  sklein-devbox-dev2.homelab.stephane-klein.info
```

### `stop`

Stops the instance gracefully (`incus stop`). Reports that it is already
stopped otherwise, and fails if the instance does not exist.

```sh
$ sklein-devbox stop
$ sklein-devbox --name dev2 stop
```

### `destroy`

Permanently deletes the instance **and all the data inside it** (home directory,
projects, configuration). Because this cannot be undone, it prints a warning and
asks you to type the instance name to confirm:

```sh
$ sklein-devbox --name dev2 destroy
WARNING: destroying instance 'sklein-devbox-dev2'.
All data inside the instance (home directory, projects, configuration)
will be permanently lost. This cannot be undone.

Type the instance name (sklein-devbox-dev2) to confirm:
```

Before deleting, it tries to remove the matching NetBird peer: this is
best-effort and is skipped (with a note) unless `NETBIRD_PAT`, `curl` and `jq`
are available. `destroy` on a non-existent instance prints a message and exits
0.

## Configuration

### Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `SKLEIN_DEVBOX_EXEC_NAME` | `sklein-devbox` | installed name and help banner |
| `SKLEIN_DEVBOX_NAME` | `dev1` | instance name → `sklein-devbox-dev1` |
| `SKLEIN_DEVBOX_FQDN_SUFFIX` | `homelab.stephane-klein.info` | instance domain |
| `SKLEIN_DEVBOX_SSH_USER` | `devbox` | SSH user |
| `SKLEIN_DEVBOX_CONFIG_DIR` | `~/.config/sklein-devbox` | configuration directory (`foot.ini`, `config.yaml`) |
| `SKLEIN_DEVBOX_CONFIG` | — | forced configuration file path |
| `SKLEIN_DEVBOX_FOOT_CONFIG` | — | forced `foot.ini` path |
| `SKLEIN_DEVBOX_FOOT_LOG_LEVEL` | `error` | foot `--log-level` (`info`, `warning`, `error`, `none`) |
| `SKLEIN_DEVBOX_TERMINAL` | `ssh` | `console` transport: `ssh` or `mosh` |
| `SKLEIN_DEVBOX_FOOT_LINK` | `1` | `console`/`foot-link` manage the reverse link (`0`/`--no-link` to disable) |
| `SKLEIN_DEVBOX_GIT_BRANCH` | `poc-reboot-to-incus-lxc-and-mise-bootstrap` | branch cloned by `up` |
| `SKLEIN_DEVBOX_DISK_SIZE` | `250GiB` | root disk size set at creation by `up`, and by `resize` |
| `SKLEIN_DEVBOX_SSH_CONFIG` | built-in | overrides the devbox `.ssh/config` content |
| `SKLEIN_DEVBOX_VERBOSE` | — | `set -x` trace inside `up` |

### Configuration file

Optional YAML file that sets a few defaults. It is resolved once, before the
built-in defaults, and read with [mikefarah
`yq`](https://github.com/mikefarah/yq) — the latter is only required when a file
is actually found. Search order, first match wins:

1. `-c FILE` / `--config FILE` (or `SKLEIN_DEVBOX_CONFIG`), used verbatim —
   a missing explicit file is an error;
2. `./.sklein-devbox.yaml` or `./.sklein-devbox.yml` in the current directory
   (development from the repository);
3. `$SKLEIN_DEVBOX_CONFIG_DIR/config.yaml` or `config.yml`, defaulting to
   `~/.config/sklein-devbox/`.

Precedence of values: **CLI flag > environment variable > config file > built-in
default**.

```yaml
name: dev2
fqdn_suffix: homelab.stephane-klein.info
terminal: ssh
disk_size: 300GiB
git_branch: poc-reboot-to-incus-lxc-and-mise-bootstrap
```

| Key | Variable | Default |
| --- | --- | --- |
| `name` | `SKLEIN_DEVBOX_NAME` | `dev1` |
| `fqdn_suffix` | `SKLEIN_DEVBOX_FQDN_SUFFIX` | `homelab.stephane-klein.info` |
| `terminal` | `SKLEIN_DEVBOX_TERMINAL` | `ssh` |
| `disk_size` | `SKLEIN_DEVBOX_DISK_SIZE` | `250GiB` |
| `git_branch` | `SKLEIN_DEVBOX_GIT_BRANCH` | `poc-reboot-to-incus-lxc-and-mise-bootstrap` |

`doctor` prints the resolved path and its origin (`explicit`, `env`, `cwd` or
`xdg`), reports a `yq` problem as an error, and exits non-zero in that case.

### `foot.ini`

`console` resolves the foot configuration in this order:

1. `SKLEIN_DEVBOX_FOOT_CONFIG` if set;
2. `$XDG_CONFIG_HOME/sklein-devbox/foot.ini`;
3. `./foot.ini` in the current directory (development from the repository);
4. foot built-in defaults.

## Installer options

```sh
$ curl -fsSL .../install.sh | bash -s -- --help
Install the sklein-devbox CLI.

Usage:
  install.sh [options]

Options:
      --version REF     Git ref or sha to install
      --bin-dir DIR     Target directory
      --exec-name NAME  Installed executable name
      --local           Install from the working tree (no network)
  -h, --help            Show this help
```

The version is the git sha1 resolved through the GitHub API. Without network
access, the installer falls back to the requested ref name. With `--local` the
sources are read from the working tree and the version is the local short git
sha.

## Development

Run the script straight from the repository:

```sh
$ ./sklein-devbox-cli/sklein-devbox --help
$ ./sklein-devbox-cli/sklein-devbox --dry-run console
```
