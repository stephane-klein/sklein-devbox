#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

# Version of the vendored catppuccin/tmux plugin. Bump it (or override with
# CATPPUCCIN_TMUX_VERSION) and re-run this script to update the plugin:
#
#   CATPPUCCIN_TMUX_VERSION=v2.4.0 mise -C sklein-devbox-mise-config run update-catppuccin-tmux
#
CATPPUCCIN_TMUX_VERSION="${CATPPUCCIN_TMUX_VERSION:-v2.3.1}"

DEST="dotfiles/.config/tmux/plugins/catppuccin/tmux"

for bin in curl tar; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "error: $bin is required to fetch catppuccin/tmux" >&2
    exit 1
  }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "==> Downloading catppuccin/tmux $CATPPUCCIN_TMUX_VERSION"
curl -fsSL \
  "https://github.com/catppuccin/tmux/archive/refs/tags/${CATPPUCCIN_TMUX_VERSION}.tar.gz" \
  | tar -xz -C "$tmp"

src="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
if [ -z "$src" ]; then
  echo "error: could not locate the extracted catppuccin/tmux source" >&2
  exit 1
fi

# Only the runtime files are vendored; assets, docs, tests and CI are dropped.
rm -rf "$DEST"
mkdir -p "$DEST/themes" "$DEST/status" "$DEST/utils"

cp "$src"/*.tmux "$src"/*.conf "$src/LICENSE" "$DEST/"
cp "$src"/themes/*.conf "$DEST/themes/"
cp "$src"/status/*.conf "$DEST/status/"
cp "$src"/utils/status_module.conf "$DEST/utils/"
chmod +x "$DEST/catppuccin.tmux"

printf '%s\n' "$CATPPUCCIN_TMUX_VERSION" >"$DEST/.version"

echo "==> catppuccin/tmux $CATPPUCCIN_TMUX_VERSION vendored into $DEST"
