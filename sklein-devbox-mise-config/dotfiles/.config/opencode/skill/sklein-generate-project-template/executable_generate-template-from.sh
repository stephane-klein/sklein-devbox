#!/bin/bash
set -euo pipefail

SOURCE_PROJECT="${1:?Usage: $0 <source_project_path> [template_output_path]}"
TEMPLATE_OUT="${2:-./template}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_MD="$SCRIPT_DIR/SKILL.md"

if [ ! -f "$SKILL_MD" ]; then
  echo "ERROR: SKILL.md not found at $SKILL_MD"
  echo "Make sure SKILL.md is in the same directory as this script: $SCRIPT_DIR"
  exit 1
fi

if [ ! -d "$SOURCE_PROJECT" ]; then
  echo "ERROR: Source project not found: $SOURCE_PROJECT"
  exit 1
fi

REAL_SOURCE="$(realpath "$SOURCE_PROJECT")"
REAL_TEMPLATE="$(realpath "$TEMPLATE_OUT")"

echo "=== sklein-generate-project-template ==="
echo "Source project : $REAL_SOURCE"
echo "Template output: $REAL_TEMPLATE"
echo ""
echo "Launching OpenCode in interactive TUI mode..."
echo ""

exec opencode \
  --prompt "Execute the sklein-generate-project-template workflow.

Source project: $REAL_SOURCE
Template output: $REAL_TEMPLATE

---

$(cat "$SKILL_MD")" \
  --auto \
  "$REAL_SOURCE"
