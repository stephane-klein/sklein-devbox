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
sklein-devbox version 20260318.0.0-d6b0178
```

Then enter your development environment from your project directory:

```sh
$ cd ~/git/github/stephane-klein/myproject/
$ sklein-devbox enter
➜  /workspace git:(main) ✗ exit
$ ./sklein-devbox list
default  /home/stephane/.local/share/sklein-devbox/default
```

For a better terminal experience, use the `console` command which opens an
[Alacritty](https://alacritty.org/) terminal with tmux pre-configured:

```sh
$ sklein-devbox console
```

> [!NOTE]
> Why two commands? `enter` vs `console`
>
> If you already run tmux on your host machine, the `enter` command
> would nest sessions, which is not ideal. The `console` command solves this by
> running tmux in a new Alacritty instance.

## Development commands

```sh
$ mise install

$ mise run git-clone-chezmoi  # Clone chezmoi configuration

$ mise run build-image      # Build the container image

$ mise run build-cli        # Build the CLI application

$ mise run enter            # Enter the container shell

$ mise run console          # Open Alacritty with tmux session

$ mise run clean-home       # Remove the persistent home directory

$ mise run fresh-enter      # Clean home + enter (fresh start)

$ mise run create-version-tag  # Create version tag

$ mise run release         # Create version tag + build on COPR
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

### Versioning

This project uses [trunk-based versioning](https://trunkver.org).

**Version format:** `YYYYMMDD.X.Y-<sha1>` (e.g., `20260318.0.0-d6b0178`)

**Release workflow:**

The release process is split into two steps for better control:

```sh
# Step 1: Create version tag
$ mise run release

# Step 2: Build SRPM from the tag and upload to COPR
$ mise run build-srpm-and-upload-to-copr
```

Step 1 (`release`) will:
1. Verify you're on `main` branch with a clean working tree
2. Compute the next version based on today's date and existing tags
3. Create a git tag

Step 2 (`build-srpm-and-upload-to-copr`) will:
1. Verify the working tree is clean and matches the latest tag
2. Build an SRPM from the tagged source
3. Upload the SRPM to COPR for building and publishing

The binary version (`--version`) includes the full version with commit SHA, while the RPM package version uses only the base version tag.

### Build RPM locally

```sh
# Build source RPM (creates rpmbuild/SRPMS/*.src.rpm)
$ mise run build-srpm

# Build full RPM (creates rpmbuild/RPMS/x86_64/*.rpm)
$ mise run build-rpm
```

### Publish on COPR

One-time setup for maintainers:

```sh
# Create COPR project (only once)
$ mise run copr-create
```

To publish a new release on COPR:

```sh
# Build SRPM from latest tag and upload to COPR
$ mise run build-srpm-and-upload-to-copr
```

### Cleanup

```sh
# Remove rpmbuild directory
$ mise run clean-rpmbuild
```

### Typical workflow

```sh
# Create version tag (Step 1)
$ mise run release

# Build and upload to COPR (Step 2)
$ mise run build-srpm-and-upload-to-copr
```
