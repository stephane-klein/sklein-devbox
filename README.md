# sklein-devbox

A personal, opinionated Podman-based development environment running Fedora 43.  
Designed to keep each project's toolchain and dependencies isolated.

## Container Image

The container image is published at: `ghcr.io/stephane-klein/sklein-devbox:latest`

## What's inside

- [mise](https://mise.jdx.dev) — runtime version manager
- [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) — editor
- [OpenCode](https://opencode.ai) — AI coding agent
- [Chezmoi](https://www.chezmoi.io/) — dotfiles manager (configuration stored in
  [sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi))
- [s6-overlay](https://github.com/just-containers/s6-overlay) — process supervisor
- openssh-server — SSH access


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
$ sklein-devbox enter        # Auto-starts container if needed, connects via SSH
➜  /workspace git:(main) ✗ exit
$ sklein-devbox status       # Shows container status and SSH port
$ sklein-devbox list
NAME    STATUS   SSH PORT  HOME PATH
default running  49234     /home/stephane/.local/share/sklein-devbox/instances/default
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

## Container lifecycle

The container runs in the background and persists until explicitly stopped:

```sh
$ sklein-devbox up           # Start container in background
$ sklein-devbox status       # Check status and SSH port
$ sklein-devbox down         # Stop and remove container
```

The `enter` and `console` commands automatically start the container if it's not running.

## Persistence and dotfiles management

The container persists user data in `~/.local/share/sklein-devbox/instances/<name>`
(the default name is `default`). This directory is bind-mounted to
`/home/sklein` inside the container. Your changes—including shell history,
Zsh customizations, and configuration files—are saved on your host workstation.

[Chezmoi](https://www.chezmoi.io/) manages dotfiles inside the container,
synchronized from a remote repository.

**Multiple instances:** Use `--name` to create isolated environments:

```sh
$ sklein-devbox --name=project-a enter   # Uses ~/.local/share/sklein-devbox/instances/project-a
$ sklein-devbox --name=project-b enter   # Uses ~/.local/share/sklein-devbox/instances/project-b
```

### Configuration Files

You can configure the CLI using configuration files and environment variables:

**Global config:** `~/.config/sklein-devbox/config.toml`

```toml
no-gopass-mount = true
no-ssh-mount = true
gopass = true
ssh-key-file = "~/.ssh/id_rsa_github"
age-key-file = "~/.secrets/age.key"
```

**Local config:** `.sklein-devbox.toml` in your project directory:

```toml
name = "myinstancename"
```

Or use environment variables:

```sh
$ SKLEIN_DEVBOX_NAME=myinstancename sklein-devbox enter
```

**Configuration priority (highest to lowest):**

1. CLI flag (e.g., `--gopass`)
2. Environment variable (e.g., `SKLEIN_DEVBOX_GOPASS`)
3. Local config (`.sklein-devbox.toml`)
4. Global config (`~/.config/sklein-devbox/config.toml`)
5. Default value

**Reset environment:** Stop the container and delete the instance directory:

```sh
$ sklein-devbox --name=default destroy    # Removes ~/.local/share/sklein-devbox/instances/default
```

## Secret Management

`sklein-devbox` supports **gopass** with **age** backend for managing secrets (passwords, API tokens) used by Chezmoi templates.

### Quick Start

Enable gopass integration with the `--gopass` flag:

```sh
$ sklein-devbox --gopass enter
```

When enabled, the Age agent starts automatically.

### How It Works

**Host with existing gopass store:** If gopass configuration is detected on the host (`~/.config/gopass/` and `~/.local/share/gopass`), these directories are automatically mounted into the container.

**Fresh host:** The user is prompted to enter the Age key in ASCII format, then the secrets repository is cloned.

### Configuration Flags

| Flag | Purpose |
|------|---------|
| `--gopass` | Enable gopass integration |
| `--no-gopass-mount` | Disable auto-mount of host gopass directories |
| `--no-ssh-mount` | Disable auto-mount of host SSH directory |
| `--ssh-key-file <path>` | Non-interactive SSH key input |
| `--age-key-file <path>` | Non-interactive Age key input |

### Secrets Repository

Secrets are stored in a private repository: <https://github.com/stephane-klein/sklein-devbox-secrets>

> [!NOTE]
> SSH Architecture
>
> The container runs `sshd` on port 2222 (mapped to a random host port).
> The CLI connects via SSH using automatically generated Ed25519 keys stored
> in `~/.local/share/sklein-devbox/ssh-client-keys/`. This provides better terminal
> compatibility than `podman run -it`, fixing issues like Ctrl-P double keystrokes
> and enabling OSC 52 clipboard integration.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, versioning, and release workflow.
