#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

podman compose exec postgres sh -c 'pg_dump --schema-only -U "$POSTGRES_USER" "$POSTGRES_DB"'