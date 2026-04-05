#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source scripts/vcs-helper.sh

if ! vcs_is_clean; then
    echo "Error: Working tree is not clean. Commit or stash your changes." >&2
    exit 1
fi

vcs=$(detect_vcs)
case "$vcs" in
    git)
        current_branch=$(vcs_current_branch)
        if [[ "$current_branch" != "main" ]]; then
            echo "Error: Must be on 'main' branch. Current branch: $current_branch" >&2
            exit 1
        fi
        ;;
    jj)
        main_commit=$(jj log --no-pager -r main -T 'commit_id' | awk 'NR==1 {print $2}')
        at_commit=$(vcs_current_full_sha)
        at_parent_commit=$(jj log --no-pager -r @- -T 'commit_id' | awk 'NR==1 {print $2}')
        if [[ "$main_commit" != "$at_commit" && "$main_commit" != "$at_parent_commit" ]]; then
            echo "Error: Must be on 'main' bookmark. Main is at $main_commit, @ is at $at_commit, @- is at $at_parent_commit" >&2
            exit 1
        fi
        ;;
    *)
        echo "Error: Unknown VCS" >&2
        exit 1
        ;;
esac

echo "Repository state is valid (on main branch, clean working tree)"
