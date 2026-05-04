# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [TrunkVer](https://trunkver.org/).

## 20260505.0.0-uvzkuyrs - 2026-05-05

### Added

- D-Bus socket mount: automatically mount host `${XDG_RUNTIME_DIR}/bus` socket into the container at `/tmp/dbus-remote.sock` when available. This enables `notify-send` and other D-Bus-based desktop notifications from within the container.

## 20260502.0.0-xkxunqsx - 2026-05-02

### Added

- Mise installs cache: mount host `~/.local/share/mise/installs/` into the container via Podman volume to avoid re-downloading tools on each rebuild. Controlled by `--mise-cache-dir` and `--no-mise-cache-mount` flags.

## 20260428.0.0-xoyvwqzk - 2026-04-28

### Fixed

- Allow running multiple containers with the same home directory from different workspaces. This was the intended behavior from the very beginning of sklein-devbox, but the implementation incorrectly prevented multiple containers from sharing a home directory when launched from different workspaces.

## 20260417.1.0-nqzluoxn - 2026-04-17

### Added

- `--from` flag on `up` command to create instances from existing ones

## 20260417.0.0-d7194fe - 2026-04-17

### Added

- Support for `~` expansion in `--ssh-key-file` and `--age-key-file` flags
- Global configuration file support: `~/.config/sklein-devbox/config.toml`

## 20260414.0.0-oolzlrnv - 2026-04-14

### Added

- New CLI commands for container lifecycle management:
  - `up` - Start container in detached mode with SSH access
  - `down` - Stop and remove container
  - `status` - Show container status, SSH port, and uptime
- SSH-based container access with automatic Ed25519 key generation
- `pkg/ssh` package for SSH key management and client connections
- `pkg/podman/container.go` for container lifecycle management

### Changed

- **BREAKING**: `enter` command now connects via SSH instead of `podman run -it`
- **BREAKING**: `console` command now uses SSH for Alacritty integration
- Container runs in detached mode (`-d`) with supervised sshd via s6-overlay
- SSH keys stored in `~/.local/share/sklein-devbox/ssh-client-keys/`
- `destroy` command now stops container before removing home directory
- `list` command shows container status and SSH port

### Fixed

- Ctrl-P double keystroke issue in OpenCode (caused by conmon PTY bridge)
- OSC 52 clipboard integration in tmux (no longer requires `TMUX=` workaround)

## 20260406.5.0-zkwxtuvo - 2026-03-06

### Added

- Secret management powered by gopass and age backend
- `--dry-run` flag for `enter` and `console` commands

## `20260318.1.0-d5bdbbb` - 2026-03-18

First release.

### Added

- Containerized development environment based on Fedora with Mise, Zsh, Neovim
- `sklein-devbox` Go CLI to manage Podman containers
- Support for multiple isolated instances with `--name` flag
- Config file support via `.sklein-devbox.toml`
- Subcommands: `list`, `destroy`, `console`
- Persistent home directory in `~/.local/share/sklein-devbox/`
- OhMyZsh and Starship prompt configuration
- Chezmoi-based dotfiles management (separate repository)
- Mise-managed tools: Neovim, OpenCode, Jujutsu, ripgrep
- COPR package build system with RPM spec

---

Version format: `YYYYMMDD.N.0-<short-hash>` (TrunkVer)
