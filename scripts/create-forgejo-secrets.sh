#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

REMOTE="forgejo"

for name in SCW_ACCESS_KEY SCW_SECRET_KEY REGISTRY_TOKEN MISE_GITHUB_TOKEN; do
  value="${!name:-}"
  if [ -z "$value" ]; then
    echo "ERROR: $name is empty (run this script under 'fnox exec')" >&2
    exit 1
  fi
  echo "Creating Forgejo Actions secret $name..."
  fj actions secrets delete "$name" -R "$REMOTE" >/dev/null 2>&1 || true
  fj actions secrets create "$name" "$value" -R "$REMOTE"
done
