# Contributing to sklein-devbox

## Development setup

```sh
$ git clone https://github.com/stephane-klein/sklein-devbox.git
$ cd sklein-devbox
$ mise install
$ mise run git-clone-chezmoi
```

## Development commands

```sh
$ mise run build-image      # Build the container image

$ mise run login-ghcr       # Login to GitHub Container Registry

$ mise run push-image       # Push image to GitHub Container Registry

$ mise run build-cli        # Build the CLI application

$ mise run enter            # Enter the container shell

$ mise run enter-no-init    # Enter container shell without init scripts

$ mise run enter-no-entrypoint  # Interactive bash shell without s6-overlay/sshd

$ mise run console          # Open Alacritty with tmux session

$ mise run clean-home       # Remove the persistent home directory

$ mise run fresh-enter      # Clean home + enter (fresh start)

$ mise run create-version-tag  # Create version tag

$ mise run release         # Create version tag + build on COPR
```

## Project structure

| Path | Description |
|------|-------------|
| `cmd/*.go` | CLI commands |
| `pkg/podman/runner.go` | Container execution logic |
| `.sklein-devbox-home/` | Persistent home directory for development |

**Architecture notes:**

- **Tasks mise** (`mise run enter/console`): Development of sklein-devbox itself, uses `./.sklein-devbox-home/`
- **CLI** (`sklein-devbox enter/console`): End users, uses `~/.local/share/sklein-devbox/<name>/`

## Container image and Chezmoi configuration separation

The `Containerfile` and `ssh-forcecommand-entrypoint.sh` files are **not** stored in this repository. They are managed in the separate repository [sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi).

### Rationale

This separation enables **atomic commits** between the container image configuration and the Chezmoi dotfiles. A Chezmoi configuration version may have dependencies on packages installed in the `Containerfile` (and vice versa). Keeping them tightly coupled in the same repository ensures that changes are versioned together and avoids inconsistencies between the container image and the dotfiles configuration.

## Versioning

This project uses [TrunkVer](https://trunkver.org) for versioning - a scheme for continuously-delivered, trunk-based applications.

**Version format:** `YYYYMMDD.X.Y-<sha1>` (e.g., `20260318.0.0-d6b0178`)

- **Timestamp**: Build date (UTC)
- **X.Y**: Sequential number for builds on same day
- **Sha1**: Git commit reference

## Release workflow

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

## Build RPM locally

```sh
# Build source RPM (creates rpmbuild/SRPMS/*.src.rpm)
$ mise run build-srpm

# Build full RPM (creates rpmbuild/RPMS/x86_64/*.rpm)
$ mise run build-rpm
```

## Publish on COPR

View the project at https://copr.fedorainfracloud.org/coprs/stephaneklein/sklein-devbox/

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

## Cleanup

```sh
# Remove rpmbuild directory
$ mise run clean-rpmbuild
```

## Publishing container images

### Prerequisites

Login to GitHub Container Registry:

```sh
$ mise run login-ghcr
```

If you get a permission error, the `gh` token may lack the `write:packages` scope.
Fix by re-authenticating with the required scopes:

```sh
$ gh auth login -s repo,write:packages,read:org
```

Alternatively, create a PAT at https://github.com/settings/tokens with `write:packages` scope:

```sh
$ podman login ghcr.io -u stephane-klein --password-stdin <<< "YOUR_PAT"
```

### Publish image

```sh
$ mise run build-image
$ mise run push-image
```

## Typical workflow

```sh
# Create version tag (Step 1)
$ mise run release

# Build and upload to COPR (Step 2)
$ mise run build-srpm-and-upload-to-copr
```

## GitHub API Rate Limiting

When using `mise install` intensively (especially with many tools or during CI), you may encounter GitHub API rate limiting errors (`403 Forbidden`).

To avoid this, provide a GitHub personal access token by adding it to your `.secret` file:

```
GITHUB_TOKEN="ghp_xxxxxxxxxxxx"
```

The `.secret` file is automatically loaded by mise (configured via `_.file = ".secret"` in `.mise.toml`) and should not be committed to git (it's already in `.gitignore`).

Create a fine-grained personal access token at https://github.com/settings/tokens with minimal permissions (e.g., `repo` scope for public repository access).
