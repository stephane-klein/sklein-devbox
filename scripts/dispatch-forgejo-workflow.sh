#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# HACK : fj actions dispatch panics while formatting its success message
# (variable $ref). forgejo-cli bug, fix in progress:
# https://codeberg.org/forgejo-contrib/forgejo-cli/pulls/674
# Remove once the fix ships in a release of fj.

WORKFLOW="${1:?usage: dispatch-forgejo-workflow.sh <workflow-file> [ref]}"
REF="${2:-poc-reboot-to-incus-lxc-and-mise-bootstrap}"
REPO="stephane-klein/sklein-devbox"

rc=0
OUTPUT="$(fj actions dispatch "$WORKFLOW" "$REF" -r "$REPO" 2>&1)" || rc=$?

if [ "$rc" -ne 0 ] && printf '%s' "$OUTPUT" | grep -q 'failed to format localized text'; then
  printf 'Workflow %s dispatched.\n' "$WORKFLOW"
  exit 0
fi
printf '%s\n' "$OUTPUT"
exit "$rc"
