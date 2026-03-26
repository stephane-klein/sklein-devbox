#!/usr/bin/env bash
set -euo pipefail

# Check if we're on main branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "main" ]]; then
    echo "Error: Must be on 'main' branch. Current branch: $current_branch" >&2
    exit 1
fi

# Check if working tree is clean
if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: Working tree is not clean. Commit or stash your changes." >&2
    exit 1
fi

echo "Repository state is valid (on main branch, clean working tree)"
