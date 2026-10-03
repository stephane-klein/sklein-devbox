---
name: sklein-devbox-environment
description: Where OpenCode runs — inside a Fedora LXC system container (Incus)
  named sklein-devbox, provisioned and configured with mise. Use when the task
  depends on the local environment (OS, package manager, tool installation,
  dotfiles, shell, headless constraints) rather than the project itself.
---

# You run inside a sklein-devbox container

You (OpenCode) execute inside a **system container**, not on the user's physical
machine and not in a virtual machine.

## Safety
- **Never destroy the container or delete content without the user's explicit
  authorization.** This covers `incus delete` (including this instance),
  `sklein-devbox destroy`, `rm -rf`, `git clean` / `git reset --hard`,
  `mise dot apply --force`, and any irreversible operation. If in doubt, stop
  and ask.

## Nature

- **LXC system container**, created and managed with **Incus**. `systemd-detect-virt`
  reports `lxc`; PID 1 is `systemd`.
- It is **not** a Docker/OCI container: full Linux userspace, systemd services, `dnf`.
- Base OS: **Fedora** (Container Image variant).
- The kernel is **shared with the host machine** — an LXC container has no kernel
  of its own.
- **Headless**: no graphical environment of its own; access is terminal-only
  (SSH / foot / tmux). A Wayland compositor is **not** present inside the
  container, but the foot host reverse-forwards its compositor socket into the
  instance (`/tmp/foot-host-wayland`), so `wl-copy`/`wl-paste` and Wayland
  clients reach the host desktop clipboard (see `ssh-tmux-login`).
- **SELinux is disabled** inside the container.
- User **`devbox`** (uid 1000), with passwordless `sudo`.
- Package manager: **`dnf`** (dnf5).
- Networking: **NetBird** (WireGuard) mesh; the container has its own FQDN.
- Hostname is `sklein-devbox-<instance>`.
- The container is **disposable**: destroying it wipes its whole filesystem. Treat
  nothing inside as permanent.

## How it is built

- The container is created and driven from the outside by the **`sklein-devbox` CLI**
  (`up` / `stop` / `destroy` / `console`).
- **mise** installs the CLI tools and applies the dotfiles.
  - Driver/config source: `~/.local/share/sklein-devbox/sklein-devbox-mise-config/`.
  - `~/.config/mise/config.toml` is the user-wide mise config (tools, aliases).
  - `mise dot` deploys `~/.config/*` as **copies**, not symlinks.
- Base system packages come from the image and the mise bootstrap (`dnf:` entries).
- Secrets are stored in **gopass** and injected with **fnox**.
- To work on the configuration itself (edit / apply / driver rules), follow the
  repository's own `AGENTS.md` at `~/.local/share/sklein-devbox/`.

## Sources

- This environment: `~/.local/share/sklein-devbox/` — the `sklein-devbox` CLI,
  the Incus image definitions, the cloud-init template, the mise config and the README.
- The host machine running Incus:
  <https://github.com/stephane-klein/incus-poc/tree/main/incus-in-coreos-server>

## Daily environment

- Login shell **zsh**; an interactive SSH login lands in **tmux**.
- Editor **Neovim** (LazyVim) — all via mise.
- Completion: mise + carapace + gopass + fzf-tab.
