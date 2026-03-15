# sklein-devbox

A personal, opinionated Podman-based development environment running Fedora 43.  
Designed to keep each project's toolchain and dependencies isolated.

## What's inside

- [mise](https://mise.jdx.dev) — runtime version manager
- [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) — editor
- [OpenCode](https://opencode.ai) — AI coding agent
- [Chezmoi](https://www.chezmoi.io/) — dotfiles manager


## Getting started

Install sklein-devbox via Fedora COPR:

```sh
$ sudo dnf copr enable stephaneklein/sklein-devbox
$ sudo dnf install sklein-devbox
$ sklein-devbox --version
sklein-devbox version 0.1.0
```

Then enter your development environment from your project directory:

```sh
$ cd ~/git/github/stephane-klein/myproject/
$ sklein-devbox enter
➜  /workspace git:(main) ✗
```

## Development commands

```sh
$ mise install

$ mise run build-image      # Build the container image

$ mise run build-cli        # Build the CLI application

$ mise run enter            # Enter the container shell

$ mise run clean-home       # Remove the persistent home directory

$ mise run fresh-enter      # Clean home + enter (fresh start)
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

## Packaging

Build and publish RPM packages via Fedora COPR.

### Build RPM locally

```sh
# Build source RPM (creates rpmbuild/SRPMS/*.src.rpm)
mise run build-srpm

# Build full RPM (creates rpmbuild/RPMS/x86_64/*.rpm)
mise run build-rpm
```

### Publish on COPR

One-time setup for maintainers:

```sh
# 1. Create COPR project (only once)
mise run copr-create

# 2. Build on COPR from local SRPM
mise run copr-build
```

### Cleanup

```sh
# Remove rpmbuild directory
mise run clean-rpmbuild
```

### Typical workflow

```sh
# After code changes, version bump in spec, etc.
mise run build-srpm      # Generate SRPM locally
mise run copr-build      # Submit to COPR for all chroots
```
