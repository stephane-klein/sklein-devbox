#!/usr/bin/env bash
CURRENT_NAME=$(tmux display-message -p '#{window_name}')

if ! name=$(gum input --placeholder 'window name...' --value "$CURRENT_NAME"); then exit 0; fi
[[ -z "$name" ]] && exit 0

tmux rename-window "$name"
