#!/usr/bin/env bash
# Usage: current-path.sh <full_path> [max_len] [levels]
FULL_PATH="${1:-$PWD}"
MAX_LEN="${2:-30}"
LEVELS="${3:-3}"

# Extract the N last segments
SHORT=$(echo "$FULL_PATH" | awk -F/ -v n="$LEVELS" '{
  start = NF - n + 1
  if (start < 1) start = 1
  path = ""
  for (i = start; i <= NF; i++) {
    path = (i == start) ? $i : path "/" $i
  }
  print path
}')

# Truncate if too long
if [ ${#SHORT} -gt $MAX_LEN ]; then
  echo "…${SHORT: -$((MAX_LEN - 1))}"
else
  echo "$SHORT"
fi
