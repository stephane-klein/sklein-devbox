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
- **Tools**: Mise, Zsh, Neovim

### Container image and Chezmoi configuration

The `Containerfile`, `entrypoint.sh`, and chezmoi dotfiles are **not** stored in this repository. They are all managed in the separate repository [sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi).

This separation enables **atomic commits** between the container image configuration and the Chezmoi dotfiles. A Chezmoi configuration version may have dependencies on packages installed in the `Containerfile` (and vice versa). Keeping them tightly coupled ensures that changes are versioned together and avoids inconsistencies.

This also allows the dotfiles configuration to be reused directly on a Fedora workstation outside the devbox.

## Workflow

When developing on sklein-devbox:

1. Changes to `Containerfile` or `entrypoint.sh` must be committed in the `sklein-devbox-chezmoi` repository
2. Changes to dotfiles (Zsh, Neovim, tmux, etc.) are also committed in the `sklein-devbox-chezmoi` repository
3. The `sklein-devbox` repository only contains the CLI application and the build infrastructure

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

## Architecture Notes

- **Tasks mise** (`mise run enter/console`): Development of sklein-devbox itself, uses `./.sklein-devbox-home/`
- **CLI** (`sklein-devbox enter/console`): End users, uses `~/.local/share/sklein-devbox/<name>/`

## Code Style Preferences

- **Inline over extraction**: When code can be placed directly where it's used or extracted to a separate function, prefer inline implementation

## Configuration Binding Convention

All CLI flags that can be configured via `.sklein-devbox.toml` **must** be bound to viper to ensure consistent behavior across config file, environment variables, and CLI flags.

### Required Pattern

For every flag that should be configurable via config file:

1. Define the flag as a `PersistentFlag` on `rootCmd` in `cmd/main.go`
2. Bind it to viper using `viper.BindPFlag()`
3. Bind it to an environment variable using `viper.BindEnv()`
4. Add a getter function in `cmd/main.go` that reads from viper (e.g., `getSecretOptions()`)

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
3. Config file value (from `.sklein-devbox.toml`)
4. Default value (hardcoded in flag definition)

## Documentation

- When adding user-facing features (CLI commands, mise tasks), update README.md accordingly.
- Keep AGENTS.md focused on development guidance for AI assistants.
