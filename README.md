# sklein-devbox

> [!NOTE]
> You are viewing an experimental branch, a reboot of the *sklein-devbox* project toward
> [Incus LXC](https://linuxcontainers.org/incus/) and [Mise bootstrap](https://mise.jdx.dev/bootstrap.html).
> For now this branch is a POC that, if successful, will become the future stable version.

## AI-Assisted Development

This project was developed using:

- [OpenCode](https://opencode.ai) CLI — coding assistant workflow (not vibe coding)
- Models: DeepSeek-v4.1-Flash (OpenCode Go)

> [!IMPORTANT]
> Everything below is aimed at a developer (me) contributing to *sklein-devbox*:
> this is the work and build environment, not the thing final users consume.
> End-user documentation for the generated devbox is not written yet.

## Tech stack

- [Incus LXC](https://linuxcontainers.org/incus/)
- [Mosh](https://github.com/mobile-shell/mosh) — optional, `ssh` is the default transport
- [Mise bootstrap](https://mise.jdx.dev/bootstrap.html)
- [mutagen](https://github.com/mutagen-io/mutagen) — optional, workstation-synced mode only

## CLI

[`sklein-devbox-cli/`](./sklein-devbox-cli/) holds the `sklein-devbox`
command-line interface, a single self-contained bash script installed over
`curl`. See its [README](./sklein-devbox-cli/README.md) for installation and
usage.

```sh
$ curl -fsSL https://raw.githubusercontent.com/stephane-klein/sklein-devbox/poc-reboot-to-incus-lxc-and-mise-bootstrap/sklein-devbox-cli/install.sh | bash
```

This is an early version: only the `console` subcommand (equivalent to
`mise run foot`) is implemented.

## Getting started

Before continuing, the `sklein-devbox-dev` image must be available in the Incus image
registry.

```sh
$ mise run incus-list-images
+--------------------------+--------------+-----------+-----------+
|         ALIASES          | FINGERPRINT  |   TYPE    |   SIZE    |
+--------------------------+--------------+-----------+-----------+
| fedora/44/cloud          | 2f28d4bab4d1 | CONTAINER | 218.51MiB |
| fedora/44/cloud/x86_64   |              |           |           |
| sklein-devbox-dev        |              |           |           |
| sklein-devbox-dev/x86_64 |              |           |           |
+--------------------------+--------------+-----------+-----------+
```

To create or update this image, follow the instructions in [`./sklein-devbox-incus-images/`](./sklein-devbox-incus-images/).

### Choose a container bootstrap mode

Two mutually exclusive modes exist. The mode is chosen when the container is
created: cloud-init only runs on first boot, so switching modes requires
destroying and recreating the container.

- **Workstation-synced (development mode)** — `mise run incus-start-lxc`. The
  mise config comes from a two-way mutagen sync of
  `./sklein-devbox-mise-config/`; mutagen is enabled. Edit files on the
  workstation and mutagen keeps the container in sync.
- **Git-bootstrapped (production mode)** —
  `mise run incus-start-lxc-with-bootstrap`. At first boot cloud-init clones
  this repository and runs the in-container bootstrap; mutagen is disabled. The
  container is self-contained and reproducible from a git ref, with no
  dependency on the workstation.

### Workstation-synced mode (mutagen)

Create and start the container, bootstrap it from the directories mounted and shared 
by Mutagen, then connect over SSH:

```sh
$ mise run incus-start-lxc
$ mise run bootstrap-sklein-devbox
$ mise run ssh
[ssh] $ ssh devbox@sklein-devbox-dev.homelab.stephane-klein.info
Last login: Wed Sep 23 09:37:56 2026 from fd0e:5069:2174:137b:7db2:51cb:33f7:339
[devbox@sklein-devbox-dev ~]$ ls
workspace
```

`./sklein-devbox-mise-config/` is kept in two-way sync into
`~/.local/share/sklein-devbox/sklein-devbox-mise-config/` by mutagen. Pause and
resume it with:

```sh
$ mise run mutagen-stop
$ mise run mutagen-start
```

### Git-bootstrapped mode (no mutagen)

Create and start the container, bootstrap it from the git repository source code,
then connect over SSH:

```sh
$ mise run incus-start-lxc-with-bootstrap
$ mise run ssh
```

On first boot, as the `devbox` user, cloud-init:

1. clones this repository into `~/.local/share/sklein-devbox/`;
2. clones the gopass store (`stephane-klein/sklein-devbox-secrets`) so `fnox`
   can resolve the bootstrap secrets;
3. runs `bootstrap-sklein-devbox.sh` (Mise + the full `mise bootstrap`).

The start script waits for cloud-init and checks the clone. **mutagen is not
started**: the git working tree is the source of truth.

The in-container bootstrap is gated by `SKLEIN_DEVBOX_BOOTSTRAP`;
`incus-start-lxc-with-bootstrap` sets both `SKLEIN_DEVBOX_GIT_CLONE=1` and
`SKLEIN_DEVBOX_BOOTSTRAP=1`. Exporting only `SKLEIN_DEVBOX_GIT_CLONE=1` clones
the repository without bootstrapping it.

The default branch is `poc-reboot-to-incus-lxc-and-mise-bootstrap`. Override it
when starting the container:

```sh
$ SKLEIN_DEVBOX_GIT_BRANCH=my-branch mise run incus-start-lxc-with-bootstrap
```

### Connect through a foot terminal

`mise run ssh` is a plain SSH session. `mise run foot` opens the same session
inside a maximized [foot](https://codeberg.org/dnkl/foot) terminal configured by
the repository [`foot.ini`](./foot.ini):

```sh
$ mise run foot
```

foot is used for what a plain terminal cannot do over the SSH + tmux chain:

- **OSC 52 clipboard** — bidirectional between the instance and the local
  desktop, through tmux: copies out (tmux copy-mode, Neovim, opencode) and
  reads in (Neovim `"+p` pastes the real host clipboard). Reading the host
  clipboard needs the terminal to answer an OSC 52 query, which `foot` does but
  mosh does not relay — so the transport defaults to `ssh`, and `mosh` is opt-in
  for roaming with clipboard *write* only (see the FAQ);
- **SIXEL image rendering** — `chafa`, `img2sixel`, and Neovim's `image.nvim`
  display images inline;
- **tmux auto-start** — `ssh -t` forces a tty and the login is routed through
  `/usr/local/bin/ssh-tmux-login`, so an interactive login lands in tmux
  directly (see [`sklein-devbox-mise-config/`](./sklein-devbox-mise-config/)).

`foot.ini` enables `osc52`, uses the Hack Nerd Font, and binds `Ctrl+Shift+F5`
to switch between the Catppuccin dark and light themes.

The `foot` task passes `-o StrictHostKeyChecking=accept-new` and
`-o UserKnownHostsFile=/dev/null`: host key verification is disabled. This is a
POC shortcut, not suitable outside this throwaway environment.

### Inspect the rendered cloud-init

Optionally, render and validate the cloud-init user-data:

```sh
$ mise run check-cloud-init
```

Renders `templates/cloud-init.yaml.jinja` with the real values from `fnox`,
validates it and prints the result. The rendered user-data is never written to
disk.

### Destroy the container

At the end of the process, you can destroy the container with:

```sh
$ mise run incus-destroy-lxc
```

Deletes the NetBird peer and the container.

## Tasks reference

All tasks are defined in the root [`.mise.toml`](./.mise.toml) and run with
`mise run <task>`.

```
$ mise task
Name                                             Description
bootstrap-sklein-devbox                          Upload the gopass access keys, then run the in-container Mise bootstrap
build-incus-builder-image                        Trigger the Forgejo Actions workflow that builds the incus-builder job image
build-lxc-image                                  Trigger the Forgejo Actions workflow that builds and publishes the LXC image
check-cloud-init                                 Render and validate cloud-init user-data with real fnox values (no secret written to disk)
console                                          Open a shell in the container (incus exec)
create-forgejo-secrets                           Create the Forgejo Actions secrets (SCW_*) used by the LXC image build workflow
foot                                             Open a foot terminal connected to sklein-devbox
incus-destroy-lxc                                Delete the NetBird peer and the container
incus-list-images                                List the images available on the sklein Incus remote
incus-start-lxc                                  Create (if needed) and start the container, workstation-synced mode
incus-start-lxc-with-bootstrap                   Create the container, clone the repo and run the mise bootstrap (mutagen disabled)
mutagen-start                                    Start the mutagen two-way sync
mutagen-stop                                     Stop the mutagen two-way sync
ssh                                              Open an SSH session as devbox
upload-gopass-access-keys                        Upload the gopass access keys (SSH key, age key, gopass config) into the container (dev only)
```

### Build and publish the image (`build-lxc-image`)

The `sklein-devbox-dev` image is built by the Forgejo Actions workflow
`.forgejo/workflows/build-lxc-image.yml`, not on the workstation. The workflow is
triggered manually:

```sh
$ mise run build-lxc-image
```

The job runs inside the custom `forgejo.sklein.internal/stephane-klein/incus-builder-image`
job image (node + mise + distrobuilder build dependencies). Before the first run,
the Scaleway credentials and the registry token must exist as Forgejo Actions
secrets (see `create-forgejo-secrets` below). To build and publish from the
workstation instead, see
[`./sklein-devbox-incus-images/`](./sklein-devbox-incus-images/).

### Build the job image (`build-incus-builder-image`)

The `incus-builder` job image is built by the Forgejo Actions workflow
`.forgejo/workflows/build-incus-builder-image.yml`. Rebuild and push it whenever
`containers/incus-builder-image/` changes:

```sh
$ mise run build-incus-builder-image
```

It requires the `REGISTRY_TOKEN` repository secret (a Forgejo personal access
token with the `write:package` scope). See
[`./containers/incus-builder-image/`](./containers/incus-builder-image/).

### Create the Forgejo Actions secrets (`create-forgejo-secrets`)

The workflow needs repository-level Forgejo Actions secrets:

- `SCW_ACCESS_KEY`, `SCW_SECRET_KEY` — Scaleway, to publish the image.
- `REGISTRY_TOKEN` — a Forgejo personal access token with the `write:package`
  scope, to push the job image.
- `MISE_GITHUB_TOKEN` — a GitHub fine-grained token with read-only access to
  public repositories, so Mise resolves the `github:` tools against
  `api.github.com` instead of the Forgejo `GITHUB_TOKEN` of the run (which
  GitHub rejects with 401).

The task reads them from `fnox` (backed by gopass) and creates (or refreshes)
them on the `forgejo` remote:

```sh
$ mise run create-forgejo-secrets
```

It is idempotent: each secret is deleted then recreated, so re-running it always
reflects the current gopass values. The `REGISTRY_TOKEN` value comes from the
`homelab/forgejo/container-registry-token` gopass entry, itself created/refreshed
by `mise run //apps/forgejo:container-registry-token` in the homelab repository;
`MISE_GITHUB_TOKEN` comes from `github/mise-ci-readonly` (create the fine-grained
token in the GitHub UI first).

## FAQ

### Why does `console` default to `ssh`, not mosh?

For the clipboard. mosh 1.4.0 only implements OSC 52 in the *write* direction:
copying from the instance to the host clipboard works, but mosh can never *read*
the host clipboard — it does not relay the `52;c;?` query that tmux sends to the
terminal. `ssh` can, so `console` defaults to it. mosh is still available with
`--terminal=mosh` (or `SKLEIN_DEVBOX_TERMINAL=mosh`) for roaming on unstable
networks, accepting that limitation; `console` prints a warning in that case.

### How does pasting from the host into Neovim work?

tmux is configured with `get-clipboard both`: an application's clipboard read
request (`"+p`) is forwarded to the terminal, which answers with the real
clipboard; tmux creates a buffer from that answer and returns it to the app. On
the `foot` side, OSC 52 reads are allowed (`security.osc52=enabled`). This works
over **ssh**; over **mosh** the query is not relayed and pasting from the host
fails — then use `Ctrl+Shift+V` (the terminal's raw paste), which does not go
through OSC 52.
