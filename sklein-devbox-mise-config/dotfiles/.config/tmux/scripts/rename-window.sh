#!/usr/bin/env bash
CURRENT_NAME=$(tmux display-message -p '#{window_name}')

name=$(gum input --placeholder 'window name...' --value "$CURRENT_NAME")

[[ $? -ne 0 ]] && exit 0
[[ -z "$name" ]] && exit 0

tmux rename-window "$name"
