#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: atomic-split.sh <command> [args...]

Commands:
  check                          Verify preconditions (jj-hunk present, working copy clean)
  list <rev>                     List hunks for a revision (jj-hunk list --rev)
  split <rev> <spec-file> <msg>  Execute jj split --no-integrate-operation --tool=jj-hunk
  integrate <op-id>...           Integrate operation IDs with jj op integrate
  plan-init <rev> <output>       Initialize an empty split plan Markdown file
  cleanup <plan-file>            Remove the plan Markdown file
EOF
  exit 1
}

cmd_check() {
  if ! command -v jj-hunk &>/dev/null; then
    echo "Error: jj-hunk is not installed." >&2
    echo "Install it with: cargo install jj-hunk" >&2
    exit 1
  fi

  if ! command -v jj &>/dev/null; then
    echo "Error: jj is not installed." >&2
    exit 1
  fi

  local wc_diff
  wc_diff=$(jj diff -r @ --summary 2>/dev/null || true)
  if [ -n "$wc_diff" ]; then
    echo "Error: working copy is not clean. jj diff -r @ shows changes:" >&2
    echo "$wc_diff" >&2
    echo "Run 'jj new' or 'jj commit' first." >&2
    exit 1
  fi

  echo "Preconditions OK: jj-hunk present, jj present, working copy clean"
}

cmd_list() {
  local rev="${1:?Usage: atomic-split.sh list <rev>}"
  jj-hunk list --rev "$rev" --format json
}

cmd_split() {
  local rev="${1:?Usage: atomic-split.sh split <rev> <spec-file> <msg>}"
  local spec_file="${2:?Missing spec-file}"
  local msg="${3:?Missing message}"

  if [ ! -f "$spec_file" ]; then
    echo "Error: spec file not found: $spec_file" >&2
    exit 1
  fi

  JJ_HUNK_SELECTION="$spec_file" jj split -i --tool=jj-hunk -r "$rev" --no-integrate-operation -m "$msg" --quiet 2>&1
}

cmd_integrate() {
  if [ $# -eq 0 ]; then
    echo "Error: at least one operation ID required" >&2
    exit 1
  fi

  local op_id
  for op_id in "$@"; do
    echo "Integrating operation: $op_id"
    jj op integrate "$op_id" --quiet
  done
  echo "All operations integrated."
}

cmd_plan_init() {
  local rev="${1:?Usage: atomic-split.sh plan-init <rev> <output>}"
  local output="${2:?Missing output file}"

  local change_id
  change_id=$(jj log -r "$rev" -T 'change_id.shortest()' --no-graph 2>/dev/null || echo "unknown")
  local original_msg
  original_msg=$(jj log -r "$rev" -T 'description.first_line()' --no-graph 2>/dev/null || echo "")

  cat > "$output" <<TEMPLATE
# Atomic split plan for $change_id

Source commit: $change_id
Original message: "$original_msg"
Revision: $rev

## Proposed atomic commits

<!-- The agent will fill this section with the decomposition plan -->

---
Status: pending validation
TEMPLATE

  echo "Plan initialized: $output"
}

cmd_cleanup() {
  local plan_file="${1:?Usage: atomic-split.sh cleanup <plan-file>}"

  if [ -f "$plan_file" ]; then
    rm "$plan_file"
    echo "Removed: $plan_file"
  fi
}

# --- Main dispatch ---
if [ $# -eq 0 ]; then
  usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
  check)      cmd_check "$@" ;;
  list)       cmd_list "$@" ;;
  split)      cmd_split "$@" ;;
  integrate)  cmd_integrate "$@" ;;
  plan-init)  cmd_plan_init "$@" ;;
  cleanup)    cmd_cleanup "$@" ;;
  -h|--help)  usage ;;
  *)          echo "Error: unknown command: $COMMAND" >&2; usage ;;
esac
