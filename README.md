# sklein-devbox

A personal, opinionated Podman-based development environment running Fedora 43.  
Designed to keep each project's toolchain and dependencies isolated.

## What's inside

- [mise](https://mise.jdx.dev) — runtime version manager
- [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) — editor
- [OpenCode](https://opencode.ai) — AI coding agent
- [Chezmoi](https://www.chezmoi.io/) — dotfiles manager

## Getting started

```sh
$ mise run build          # Build the container image

$ mise run enter          # Enter the container shell

$ mise run clean-home     # Remove the persistent home directory

$ mise run fresh-enter   # Clean home + enter (fresh start)
```

## Persistence and dotfiles management

This container uses a bind-mounted directory at `./.sklein-devbox-home/` 
to persist user preferences across sessions. Your changes—including 
shell history, OhMyZsh customizations, and configuration files—are 
saved directly on your host workstation.

[Chezmoi](https://www.chezmoi.io/) manages dotfiles, enabling configuration 
sharing between this container and your host workstation. On first launch, 
Chezmoi automatically initializes from `./chezmoi/` (local development) or 
from the shared remote repository.

**First run:** The `.sklein-devbox-home/` directory is created automatically. 
To reset your environment, simply run `mise run fresh-enter` (or manually delete 
the directory and re-enter the container).
