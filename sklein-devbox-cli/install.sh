#!/usr/bin/env bash
set -euo pipefail

REPO="${SKLEIN_DEVBOX_REPO:-stephane-klein/sklein-devbox}"
REF="${SKLEIN_DEVBOX_VERSION:-poc-reboot-to-incus-lxc-and-mise-bootstrap}"
BIN_DIR="${SKLEIN_DEVBOX_BIN_DIR:-$HOME/.local/bin}"
EXEC_NAME="${SKLEIN_DEVBOX_EXEC_NAME:-sklein-devbox}"
CONF_DIR="${SKLEIN_DEVBOX_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/sklein-devbox}"
LOCAL=0

usage() {
  cat <<EOF
Install the sklein-devbox CLI.

Usage:
  install.sh [options]

Options:
      --version REF     Git ref or sha to install (default "$REF")
      --bin-dir DIR     Target directory (default "$BIN_DIR")
      --exec-name NAME  Installed executable name (default "$EXEC_NAME")
      --local           Install from the working tree (no network)
  -h, --help            Show this help

Environment:
  SKLEIN_DEVBOX_REPO         Repository (default "$REPO")
  SKLEIN_DEVBOX_VERSION      Same as --version
  SKLEIN_DEVBOX_BIN_DIR      Same as --bin-dir
  SKLEIN_DEVBOX_EXEC_NAME    Same as --exec-name
  SKLEIN_DEVBOX_CONFIG_DIR   foot.ini directory (default "$CONF_DIR")
  GITHUB_TOKEN / GH_TOKEN    Raises the GitHub API rate limit
EOF
}

while (( $# )); do
  case "$1" in
    --version)    REF="${2:?--version requires a value}"; shift 2 ;;
    --version=*)  REF="${1#*=}"; shift ;;
    --bin-dir)    BIN_DIR="${2:?--bin-dir requires a value}"; shift 2 ;;
    --bin-dir=*)  BIN_DIR="${1#*=}"; shift ;;
    --exec-name)  EXEC_NAME="${2:?--exec-name requires a value}"; shift 2 ;;
    --exec-name=*) EXEC_NAME="${1#*=}"; shift ;;
    --local)      LOCAL=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            printf 'unknown flag: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$EXEC_NAME" ] || { printf 'error: --exec-name must not be empty\n' >&2; exit 2; }

declare -a auth=()
if [ -n "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]; then
  auth=(-H "Authorization: Bearer ${GITHUB_TOKEN:-$GH_TOKEN}")
fi

if (( LOCAL )); then
  if [ -z "${BASH_SOURCE[0]:-}" ]; then
    printf 'error: --local requires running install.sh from a file\n' >&2
    exit 2
  fi
  SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  sha="$(git -C "$SCRIPT_DIR/.." rev-parse --short HEAD 2>/dev/null || true)"
  sha="${sha:-dev}"
  script_src="$SCRIPT_DIR/sklein-devbox"
  foot_src="$SCRIPT_DIR/../foot.ini"
else
  sha="$(curl -fsSL "${auth[@]}" -H 'Accept: application/vnd.github.sha' \
    "https://api.github.com/repos/${REPO}/commits/${REF}" 2>/dev/null || true)"
  sha="${sha:-$REF}"
  base="https://raw.githubusercontent.com/${REPO}/${sha}"
  script_src="$base/sklein-devbox-cli/sklein-devbox"
  foot_src="$base/foot.ini"
fi

tmp="$(mktemp)"
stamped="${tmp}.stamped"
trap 'rm -f "$tmp" "$stamped"' EXIT

if (( LOCAL )); then
  printf 'Installing local working tree version %s...\n' "$sha" >&2
  cp "$script_src" "$tmp"
else
  printf 'Downloading %s version %s...\n' "$REPO" "$sha" >&2
  curl -fsSL "${auth[@]}" "$script_src" -o "$tmp"
fi
sed "s|^readonly VERSION=.*|readonly VERSION=\"${sha}\"|" "$tmp" > "$stamped"
bash -n "$stamped"

install -d "$BIN_DIR"
install -m 0755 "$stamped" "$BIN_DIR/$EXEC_NAME"

install -d "$CONF_DIR"
if (( LOCAL )); then
  install -m 0644 "$foot_src" "$CONF_DIR/foot.ini"
else
  printf 'Downloading foot.ini...\n' >&2
  curl -fsSL "${auth[@]}" "$foot_src" -o "$CONF_DIR/foot.ini"
fi

printf 'Installed %s in %s\n' "$EXEC_NAME" "$BIN_DIR"
printf 'Installed foot.ini in %s\n' "$CONF_DIR"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) printf 'warning: %s is not in PATH\n' "$BIN_DIR" >&2 ;;
esac

shell_detected="$(basename "${SHELL:-}")"
case "$shell_detected" in
  bash|zsh|fish)
    "$BIN_DIR/$EXEC_NAME" completion install "$shell_detected" || true
    ;;
  *)
    printf 'note: unknown shell "%s"; run "%s completion install <bash|zsh|fish>" manually\n' "${shell_detected:-none}" "$EXEC_NAME" >&2
    ;;
esac
