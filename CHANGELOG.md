# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [TrunkVer](https://trunkver.org/).

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
