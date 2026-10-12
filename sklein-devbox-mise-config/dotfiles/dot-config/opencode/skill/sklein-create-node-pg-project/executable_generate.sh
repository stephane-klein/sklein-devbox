#!/bin/bash
set -euo pipefail

template_dir="${1%/}"
vars_file="$2"
target_dir="${3%/}"

include_gopass_setup_secret=$(yq '.include_gopass_setup_secret' "$vars_file")

mkdir -p "$target_dir"

cp "$template_dir/.containerignore" "$target_dir/.containerignore"
cp "$template_dir/.editorconfig" "$target_dir/.editorconfig"
minijinja-cli "$template_dir/.envrc.jinja" "$vars_file" > "$target_dir/.envrc"
cp "$template_dir/.gitignore" "$target_dir/.gitignore"
cp "$template_dir/biome.jsonc" "$target_dir/biome.jsonc"
cp "$template_dir/.secret.example" "$target_dir/.secret.example"
cp "$template_dir/.npmrc" "$target_dir/.npmrc"
cp "$template_dir/Containerfile" "$target_dir/Containerfile"
cp "$template_dir/LICENSE" "$target_dir/LICENSE"
cp "$template_dir/compose.yaml" "$target_dir/compose.yaml"
cp "$template_dir/entrypoint.sh" "$target_dir/entrypoint.sh"
minijinja-cli "$template_dir/AGENTS.md.jinja" "$vars_file" > "$target_dir/AGENTS.md"
minijinja-cli "$template_dir/NEXT_STEPS.md.jinja" "$vars_file" > "$target_dir/NEXT_STEPS.md"
minijinja-cli "$template_dir/README.md.jinja" "$vars_file" > "$target_dir/README.md"
minijinja-cli "$template_dir/package.json.jinja" "$vars_file" > "$target_dir/package.json"
minijinja-cli "$template_dir/.mise.toml.jinja" "$vars_file" > "$target_dir/.mise.toml"


mkdir -p "$target_dir/scripts"
cp "$template_dir/scripts/dump-schema.sh" "$target_dir/scripts/dump-schema.sh"
cp "$template_dir/scripts/load_postgres_variables.sh" "$target_dir/scripts/load_postgres_variables.sh"

mkdir -p "$target_dir/sqls"
cp "$template_dir/sqls/clean.sql" "$target_dir/sqls/clean.sql"
cp "$template_dir/sqls/schema.sql" "$target_dir/sqls/schema.sql"

mkdir -p "$target_dir/sqls/fixtures"
cp "$template_dir/sqls/fixtures/00001_contacts.sql" "$target_dir/sqls/fixtures/00001_contacts.sql"

mkdir -p "$target_dir/sqls/migrations/00001_initial"
cp "$template_dir/sqls/migrations/00001_initial/index.sql" "$target_dir/sqls/migrations/00001_initial/index.sql"

mkdir -p "$target_dir/src"
cp "$template_dir/src/db.js" "$target_dir/src/db.js"
cp "$template_dir/src/hello_world.js" "$target_dir/src/hello_world.js"
cp "$template_dir/src/logger.js" "$target_dir/src/logger.js"
cp "$template_dir/src/migrate.js" "$target_dir/src/migrate.js"
cp "$template_dir/src/seed.js" "$target_dir/src/seed.js"

mkdir -p "$target_dir/deployment-playground/"
cp "$template_dir/deployment-playground/README.md" "$target_dir/deployment-playground/README.md"
minijinja-cli "$template_dir/deployment-playground/.env.jinja" "$vars_file" > "$target_dir/deployment-playground/.env"
minijinja-cli "$template_dir/deployment-playground/compose.yml.jinja" "$vars_file" > "$target_dir/deployment-playground/compose.yml"

if [ "$include_gopass_setup_secret" = "true" ]; then
  mkdir -p "$target_dir/scripts"
  minijinja-cli "$template_dir/scripts/generate-secret.sh.jinja" "$vars_file" > "$target_dir/scripts/generate-secret.sh"
fi
