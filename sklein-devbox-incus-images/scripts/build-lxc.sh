#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

DISTROBUILDER_BIN="$(mise which distrobuilder)"
sudo incus image delete sklein-devbox-dev >/dev/null 2>&1 || true
sudo systemd-run --scope --quiet \
  -p CPUQuota=200% \
  -p MemoryHigh=6G \
  -p MemoryMax=10G \
  -p IOWeight=1 \
  -- "$DISTROBUILDER_BIN" build-incus fedora.yaml dist/sklein-devbox-dev \
  --sources-dir .distrobuilder-sources;

sudo chown -R $USER:$USER dist/sklein-devbox-dev
ls -lha dist/sklein-devbox-dev
