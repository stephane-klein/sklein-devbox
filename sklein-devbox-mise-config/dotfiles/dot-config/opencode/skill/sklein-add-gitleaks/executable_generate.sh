#!/bin/bash
set -euo pipefail

template_dir="${1%/}"
vars_file="$2"
target_dir="${3%/}"

mkdir -p "$target_dir"

# Parse vars
use_jujutsu=$(yq '.use_jujutsu' "$vars_file")

# Create directories
mkdir -p "$target_dir/git-hooks"
mkdir -p "$target_dir/scripts"

# Static files (non-templated)
cp "$template_dir/git-hooks/pre-commit" "$target_dir/git-hooks/pre-commit"
cp "$template_dir/scripts/gitleaks-check-push.sh" "$target_dir/scripts/gitleaks-check-push.sh"
cp "$template_dir/scripts/setup-git-hooks.sh" "$target_dir/scripts/setup-git-hooks.sh"

# Conditionally copy jj alias script
if [ "$use_jujutsu" = "true" ]; then
  cp "$template_dir/scripts/setup-jj-alias.sh" "$target_dir/scripts/setup-jj-alias.sh"
fi

# Render Jinja templates
minijinja-cli "$template_dir/.gitleaks.toml.jinja" "$vars_file" > "$target_dir/.gitleaks.toml"
