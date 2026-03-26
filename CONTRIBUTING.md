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

$ mise run build-cli        # Build the CLI application

$ mise run enter            # Enter the container shell

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

## Typical workflow

```sh
# Create version tag (Step 1)
$ mise run release

# Build and upload to COPR (Step 2)
$ mise run build-srpm-and-upload-to-copr
```