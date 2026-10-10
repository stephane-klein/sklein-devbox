#!/usr/bin/env bash
set -euo pipefail

# Run shellcheck over every shell script tracked by git, selected by shebang
# (bash or sh). Markdown files and other languages are skipped. Invoked by the
# `lint` mise task.

cd "$(dirname "$0")/.."

command -v shellcheck >/dev/null 2>&1 \
  || { echo "lint-shell: shellcheck not found in PATH" >&2; exit 127; }

files=()
while IFS= read -r file; do
  [ -f "$file" ] || continue
  IFS= read -r shebang < "$file" || continue
  case "$shebang" in
    '#!'*bash*|'#!/bin/sh'|'#!/usr/bin/sh'|'#!/usr/bin/env sh') files+=("$file") ;;
  esac
done < <(git ls-files)

if [ "${#files[@]}" -eq 0 ]; then
  echo "lint-shell: no shell scripts found" >&2
  exit 0
fi

exec shellcheck -- "${files[@]}"
