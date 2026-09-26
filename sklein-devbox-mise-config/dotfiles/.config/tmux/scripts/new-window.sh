#!/usr/bin/env bash
TMPFILE=$(mktemp /tmp/tmux-winname.XXXXXX)
CURRENT_PATH=$(tmux display-message -p '#{pane_current_path}')

tmux display-popup -E -w 50 -h 5 \
  "gum input --placeholder 'window name...' > $TMPFILE"

exit_code=$?
name=$(cat "$TMPFILE")
rm -f "$TMPFILE"

if [[ $exit_code -ne 0 ]]; then
  exit 0
fi

if [[ -z "$name" ]]; then
  name=$(mise exec --cd / -- petname)
fi

tmux new-window -a -c "$CURRENT_PATH" -n "$name"
