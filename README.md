# sklein-devbox

A personal, opinionated Podman-based development environment running Fedora 43.  
Designed to keep each project's toolchain and dependencies isolated.

## What's inside

- [mise](https://mise.jdx.dev) — runtime version manager
- [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) — editor
- [OpenCode](https://opencode.ai) — AI coding agent
- [Chezmoi](https://www.chezmoi.io/) — dotfiles manager (configuration stored in
  [sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi))


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
➜  /workspace git:(main) ✗ exit
$ ./sklein-devbox list
default  /home/stephane/.local/share/sklein-devbox/default
```

## Development commands

```sh
$ mise install

$ mise run git-clone-chezmoi  # Clone chezmoi configuration

$ mise run build-image      # Build the container image

$ mise run build-cli        # Build the CLI application

$ mise run enter            # Enter the container shell

$ mise run clean-home       # Remove the persistent home directory

$ mise run fresh-enter      # Clean home + enter (fresh start)
```

## Persistence and dotfiles management

The container persists user data in `~/.local/share/sklein-devbox/<name>`
(the default name is `default`). This directory is bind-mounted to
`/home/sklein` inside the container. Your changes—including shell history,
Zsh customizations, and configuration files—are saved on your host workstation.

[Chezmoi](https://www.chezmoi.io/) manages dotfiles inside the container,
synchronized from a remote repository.

**Multiple instances:** Use `--name` to create isolated environments:

```sh
$ sklein-devbox --name=project-a enter   # Uses ~/.local/share/sklein-devbox/project-a
$ sklein-devbox --name=project-b enter   # Uses ~/.local/share/sklein-devbox/project-b
```

*Configuration:* You can configure the instance name using a `.sklein-devbox.toml` file in your project directory:

```toml
name = "myinstancename"
```

Or use the `SKLEIN_DEVBOX_NAME` environment variable:

```sh
$ SKLEIN_DEVBOX_NAME=myinstancename sklein-devbox enter
```

Configuration priority (highest to lowest): command line flag → environment variable → config file → default value ("default").

**Reset environment:** Delete the instance directory:

```sh
$ sklein-devbox --name=default destroy    # Removes ~/.local/share/sklein-devbox/default
```

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
