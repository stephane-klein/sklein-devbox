# Project Goal

This project provides a portable and reproducible development environment, named here sklein-devbox.  
It consists of two main parts:

- A Podman container image (based on Fedora) that contains a complete development environment.  
  The home configuration is managed by Chezmoi, and tools are installed via Mise.
- A Go CLI (`sklein-devbox`) that allows instantiating containers based on this image. The home directory of these 
  environments is persistent, allowing data and configurations to be preserved between sessions.

# Language

All content must be in English: source code, comments, and documentation.

# Image Reference

This project uses **Podman**, not Docker.

## Container Image

- **Name**: `sklein-devbox`
- **Base**: Fedora 43
- **Tools**: Mise, Zsh, Neovim

## Chezmoi Configuration Separation

The chezmoi dotfiles configuration is maintained in a separate repository:
[stephane-klein/sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi).

This separation ensures that:
- Only the actual dotfiles (not project files like `Containerfile`, `go.mod`, etc.) are applied to the home directory
- The configuration can be reused directly on a Fedora workstation outside the devbox
- Cleaner separation of concerns between the devbox infrastructure and user configuration

## Development commands

```sh
$ mise install

$ mise run git-clone-chezmoi  # Clone chezmoi configuration

$ mise run build-image      # Build the container image

$ mise run build-cli        # Build the CLI application

$ mise run enter            # Enter the container shell

$ mise run clean-home       # Remove the persistent home directory

$ mise run fresh-enter      # Clean home + enter (fresh start)

$ mise run console          # Open Alacritty with tmux session
```

## CLI Commands (for end users)

| Command   | Purpose                        |
|-----------|--------------------------------|
| `enter`   | Interactive shell in container |
| `console` | Alacritty + tmux session       |
| `list`    | List instances                 |
| `destroy` | Delete instance                |

## Key Go Files

- `cmd/*.go` - CLI commands
- `pkg/podman/runner.go` - Container execution logic

## Architecture Notes

- **Tasks mise** (`mise run enter/console`): Development of sklein-devbox itself, uses `./.sklein-devbox-home/`
- **CLI** (`sklein-devbox enter/console`): End users, uses `~/.local/share/sklein-devbox/<name>/`

## Documentation

- When adding user-facing features (CLI commands, mise tasks), update README.md accordingly.
- Keep AGENTS.md focused on development guidance for AI assistants.
