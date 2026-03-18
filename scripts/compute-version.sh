#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

cd "$(dirname "$0")/.."

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "main" ]]; then
    echo "Error: Must be on 'main' branch. Current branch: $current_branch" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: Working tree is not clean. Commit or stash your changes." >&2
    exit 1
fi

date_prefix=$(date +%Y%m%d)

existing_tags=$(git tag -l "${date_prefix}.*")
count=0
if [[ -n "$existing_tags" ]]; then
    count=$(echo "$existing_tags" | wc -l)
fi

subver=$count

sha=$(git rev-parse --short HEAD)
version="${date_prefix}.${subver}.0-${sha}"

if [[ "$DRY_RUN" == true ]]; then
    echo "$version"
    exit 0
fi

git tag -a "$version" -m "Release"
echo "Created tag: $version"

git push --tags
echo "Pushed tag: $version"
