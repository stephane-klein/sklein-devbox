#!/usr/bin/env bash
export PATH="$HOME/.local/share/mise/shims:$PATH"
SESSION=$(tmux display-message -p '#{session_name}')
FIRST_WINDOW=$(tmux list-windows -t "$SESSION" -F '#{window_index}' | head -1)
tmux rename-window -t "${SESSION}:${FIRST_WINDOW}" "$(mise exec --cd / -- petname)"
