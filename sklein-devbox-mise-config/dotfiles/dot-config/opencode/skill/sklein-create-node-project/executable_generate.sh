#!/bin/bash
set -euo pipefail

template_dir="${1%/}"
vars_file="$2"
target_dir="${3%/}"

mkdir -p "$target_dir"

include_gopass_setup_secret=$(yq '.include_gopass_setup_secret' "$vars_file")

cp "$template_dir/.editorconfig" "$target_dir/.editorconfig"
cp "$template_dir/.gitignore" "$target_dir/.gitignore"
cp "$template_dir/biome.jsonc" "$target_dir/biome.jsonc"

cp "$template_dir/.secret.example" "$target_dir/.secret.example"
cp "$template_dir/.npmrc" "$target_dir/.npmrc"

minijinja-cli "$template_dir/.mise.toml.jinja" "$vars_file" > "$target_dir/.mise.toml"
minijinja-cli "$template_dir/AGENTS.md.jinja" "$vars_file" > "$target_dir/AGENTS.md"
minijinja-cli "$template_dir/NEXT_STEPS.md.jinja" "$vars_file" > "$target_dir/NEXT_STEPS.md"
minijinja-cli "$template_dir/README.md.jinja" "$vars_file" > "$target_dir/README.md"
minijinja-cli "$template_dir/package.json.jinja" "$vars_file" > "$target_dir/package.json"

if [ "$include_gopass_setup_secret" = "true" ]; then
  mkdir -p "$target_dir/scripts"
  minijinja-cli "$template_dir/scripts/generate-secret.sh.jinja" "$vars_file" > "$target_dir/scripts/generate-secret.sh"
fi
