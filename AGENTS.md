# AGENTS.md

## Project Goal

This project provides a portable and reproducible development environment, named here sklein-devbox.  
It consists of two main parts:

- A Podman container image (based on Fedora) that contains a complete development environment.  
  The home configuration is managed by Chezmoi, and tools are installed via Mise.
- A Go CLI (`sklein-devbox`) that allows instantiating containers based on this image. The home directory of these 
  environments is persistent, allowing data and configurations to be preserved between sessions.

## Language

All content must be in English: source code, comments, and documentation.

## Version Control

This repository might be managed by [Jujutsu](https://jj.rs/) (jj), a decentralized version control system.

To verify if jj is used, check for a `.jj/` directory at the repo root. If jj is active, use `jj` commands instead of `git`.

## Versioning

This project uses [TrunkVer](https://trunkver.org) for versioning - a scheme for continuously-delivered, trunk-based applications.

Version format: `YYYYMMDD.N.0-<short-hash>`

- **Timestamp**: Build date (UTC)
- **N**: Sequential number for builds on same day
- **Short hash**: Git commit reference

Examples from this project:
- `20260326.0.0-f4a1dd6`
- `20260318.1.0-d5bdbbb`

TrunkVer is SemVer-compatible and suited for projects that release frequently without manual version management.

## Image Reference

### Container Image

- **Name**: `sklein-devbox`
- **Base**: Fedora 43
- **Tools**: Mise, Zsh, Neovim, s6-overlay, openssh-server

### Container image and Chezmoi configuration

The `Containerfile`, `ssh-forcecommand-entrypoint.sh`, and chezmoi dotfiles are **not** stored in this repository. They are all managed in the separate repository [sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi).

This separation enables **atomic commits** between the container image configuration and the Chezmoi dotfiles. A Chezmoi configuration version may have dependencies on packages installed in the `Containerfile` (and vice versa). Keeping them tightly coupled ensures that changes are versioned together and avoids inconsistencies.

This also allows the dotfiles configuration to be reused directly on a Fedora workstation outside the devbox.

## Workflow

When developing on sklein-devbox:

1. Changes to `Containerfile` or `ssh-forcecommand-entrypoint.sh` must be committed in the `sklein-devbox-chezmoi` repository
2. Changes to dotfiles (Zsh, Neovim, tmux, etc.) are also committed in the `sklein-devbox-chezmoi` repository
3. The `sklein-devbox` repository only contains the CLI application and the build infrastructure

## Development commands

```sh
$ mise install

$ mise run git-clone-chezmoi  # Clone chezmoi configuration

$ mise run build-image      # Build the container image

$ mise run build-cli        # Build the CLI application

$ mise run up               # Start the devbox container (detached mode with SSH)

$ mise run down             # Stop and remove the devbox container

$ mise run status           # Show container status and SSH port

$ mise run enter            # Enter the container via SSH (requires 'mise run up' first)

$ mise run clean-home       # Remove the persistent home directory

$ mise run fresh-enter      # Clean home + up + enter (fresh start)

$ mise run console          # Open Alacritty with SSH + tmux session
```

## CLI Commands (for end users)

| Command   | Scope                              | Purpose                        |
|-----------|------------------------------------|--------------------------------|
| `up`      | `(homeName, workspace)`            | Start container in background  |
| `down`    | `(homeName, workspace)`            | Stop and remove container      |
| `status`  | `(homeName, workspace)`            | Show container status and SSH port |
| `enter`   | `(homeName, workspace)`            | Connect via SSH (auto-starts if needed) |
| `console` | `(homeName, workspace)`            | Alacritty + SSH + tmux session |
| `list`    | all                                | List all containers and homes  |
| `destroy` | `homeName` (blocks if in use)      | Delete home directory          |

## Architecture Notes

- **Tasks mise** (`mise run up/enter/console`): Development of sklein-devbox itself, uses `./.sklein-devbox-home/` and SSH keys in `./.sklein-devbox-ssh-client-keys/`
- **CLI** (`sklein-devbox up/enter/console`): End users, uses `~/.local/share/sklein-devbox/instances/<name>/` and SSH keys in `~/.local/share/sklein-devbox/ssh-client-keys/`

### Container Identity

Each container is uniquely identified by the pair **(homeName, workspacePath)**:

- **Container name**: `sklein-devbox-<homeName>-<8-char-hash>` where the hash is derived from the absolute workspace path (FNV-1a)
- **Labels**: `sklein-devbox-name=<homeName>` and `sklein-devbox-workspace=<absolute_path>`

This enables multiple containers to share the same home directory while serving different workspaces.

### Container Startup (s6-overlay)

When `up` starts the container:

1. **Podman run** - Container starts in detached mode (`-d`) with s6-overlay as PID 1 (`/init`)
2. **Init phase** (`/etc/cont-init.d/`) - One-time setup:
   - Generate SSH host keys (if missing)
   - Save environment variables to `/home/sklein/.config/sklein-devbox/env`
3. **Service startup** (`/etc/services.d/`) - Supervised services start:
   - `sshd` - Main foreground service (port 2222), configured with `ForceCommand`

#### First SSH Connection (Interactive Setup)

The `sshd` uses `ForceCommand` to always execute `/usr/local/bin/ssh-forcecommand-entrypoint.sh`, which handles lazy initialization on first connection:

```
SSH connection → ForceCommand → ssh-forcecommand-entrypoint.sh → shell/command
```

**Entrypoint script logic:**

| Check | Action |
|-------|--------|
| `SSH_ORIGINAL_COMMAND=healthcheck` | Return "ready" immediately |
| No `~/.config/gopass/age/identities` | Prompt for AGE key + passphrase, setup gopass |
| `SKLEIN_DEVBOX_GOPASS=1` and no store | Clone secrets repo via SSH |
| No `~/.local/share/chezmoi` | `chezmoi init` the dotfiles repo |
| No `~/.config/chezmoi/chezmoistate.boltdb` | `chezmoi apply` the configuration |

Once initialization is complete, the script executes the original command (or `/bin/zsh` if none).

**Key design:** All interactive prompts (AGE key, passphrase) happen during the SSH session, allowing the user to input secrets securely in their terminal.

### `enter` Command

Connects to the container via SSH and starts an interactive shell directly in the current terminal:

```
Current Terminal → ssh (PTY on host) → sshd → zsh
```

This command provides quick shell access in your existing terminal window.

Attention, the `enter` command does not launch tmux.

### `console` Command (Alacritty + tmux)

Opens a new Alacritty window with an SSH connection and starts tmux inside the container:

```
Alacritty → ssh (PTY on host) → sshd → zsh → tmux
```

This command is useful when you already run tmux on your host machine and want to avoid nested tmux sessions. By opening a new Alacritty window, you get a clean terminal for the container's tmux session. The PTY is allocated by the SSH client on the host side (single PTY), avoiding the conmon PTY bridge that caused some double keystroke issues (like [issue 13](https://github.com/stephane-klein/sklein-devbox/issues/13)).

## Code Style Preferences

- **Inline over extraction**: When code can be placed directly where it's used or extracted to a separate function, prefer inline implementation

## Configuration Binding Convention

All CLI flags that can be configured via `.sklein-devbox.toml` **must** be bound to viper to ensure consistent behavior across config file, environment variables, and CLI flags.

### Required Pattern

For every flag that should be configurable via config file:

1. Define the flag as a `PersistentFlag` on `rootCmd` in `cmd/main.go`
2. Bind it to viper using `viper.BindPFlag()`
3. Bind it to an environment variable using `viper.BindEnv()`
4. Add a getter function in `cmd/main.go` that reads from viper (e.g., `getContainerOptions()`)

#### Example

```go
// In cmd/main.go init()
rootCmd.PersistentFlags().Bool("gopass", false, "Enable gopass integration")
viper.BindPFlag("gopass", rootCmd.PersistentFlags().Lookup("gopass"))
viper.BindEnv("gopass", "SKLEIN_DEVBOX_GOPASS")
```

## Priority Order

When a value is resolved:
1. CLI flag (explicitly provided on command line)
2. Environment variable (if set)
3. Local config file value (from `.sklein-devbox.toml`)
4. Global config file value (from `~/.config/sklein-devbox/config.toml`)
5. Default value (hardcoded in flag definition)

## Boolean Flag Convention

For boolean flags that default to `true`, prefer adding only the negation form (`--no-*`) rather than both `--flag` and `--no-flag`. This keeps the CLI simpler and follows the existing pattern in the project:

**Preferred:**
```go
rootCmd.PersistentFlags().Bool("no-network-host", false, "Disable host network mode")
```

**Avoid:**
```go
rootCmd.PersistentFlags().Bool("network-host", true, "Enable host network mode")
rootCmd.PersistentFlags().Bool("no-network-host", false, "Disable host network mode")
```

This convention applies to flags like: `--no-gopass-mount`, `--no-ssh-mount`, `--no-mise-cache-mount`, `--no-pulse-audio`, etc.

## Documentation

- When adding user-facing features (CLI commands, mise tasks), update README.md accordingly.
- Keep AGENTS.md focused on development guidance for AI assistants.
