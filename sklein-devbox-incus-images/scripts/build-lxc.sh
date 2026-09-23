#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# Resolve the absolute path: on a workstation distrobuilder is launched through
# `sudo systemd-run` and sudo resets PATH to secure_path, so a bare command name
# would not be found. Invoke this script through `mise run build-lxc` so the
# tool is on PATH.
DISTROBUILDER_BIN="$(command -v distrobuilder)"

# `incus` is only available on a workstation that has an Incus daemon: on CI
# (job container) the binary is absent and there is no daemon to talk to, so
# skip the local cache cleanup.
if command -v incus >/dev/null 2>&1; then
  sudo incus image delete sklein-devbox-dev >/dev/null 2>&1 || true
fi

# On a workstation the build is pinned to a cgroup scope so it cannot starve
# the rest of the machine (sudo + systemd-run). In a CI job container neither
# systemd nor sudo is available, so run distrobuilder directly.
if command -v systemd-run >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  sudo systemd-run --scope --quiet \
    -p CPUQuota=200% \
    -p MemoryHigh=6G \
    -p MemoryMax=10G \
    -p IOWeight=1 \
    -- "$DISTROBUILDER_BIN" build-incus fedora.yaml dist/sklein-devbox-dev \
    --sources-dir .distrobuilder-sources
else
  "$DISTROBUILDER_BIN" build-incus fedora.yaml dist/sklein-devbox-dev \
    --sources-dir .distrobuilder-sources
fi

# distrobuilder runs as root on a workstation: hand the output back to the
# current user. Nothing to do in CI where the job already runs as the owner.
sudo chown -R $USER:$USER dist/sklein-devbox-dev 2>/dev/null || true
ls -lha dist/sklein-devbox-dev
