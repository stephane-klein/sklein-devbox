#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

# Version of the vendored fzf-tab plugin. Bump it (or override with
# FZF_TAB_VERSION) and re-run this script to update the plugin:
#
#   FZF_TAB_VERSION=v1.3.0 mise -C sklein-devbox-mise-config run update-fzf-tab
#
FZF_TAB_VERSION="${FZF_TAB_VERSION:-v1.3.0}"

DEST="dotfiles/.config/zsh/fzf-tab"

for bin in curl tar; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "error: $bin is required to fetch fzf-tab" >&2
    exit 1
  }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "==> Downloading fzf-tab $FZF_TAB_VERSION"
curl -fsSL \
  "https://github.com/Aloxaf/fzf-tab/archive/refs/tags/${FZF_TAB_VERSION}.tar.gz" \
  | tar -xz -C "$tmp"

src="$(find "$tmp" -maxdepth 1 -mindepth 1 -type d | head -n 1)"
if [ -z "$src" ]; then
  echo "error: could not locate the extracted fzf-tab source" >&2
  exit 1
fi

# Only the runtime files are vendored; docs, tests and CI are dropped.
# The optional `modules/` zsh binary module is not needed.
rm -rf "$DEST"
mkdir -p "$DEST/lib"

cp "$src"/fzf-tab.plugin.zsh "$src"/fzf-tab.zsh "$src"/LICENSE "$DEST/"
cp -R "$src"/lib/. "$DEST/lib/"

printf '%s\n' "$FZF_TAB_VERSION" >"$DEST/.version"

echo "==> fzf-tab $FZF_TAB_VERSION vendored into $DEST"
