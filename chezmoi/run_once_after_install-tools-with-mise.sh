#!/bin/bash
if [ -f "$HOME/.config/mise/config.toml" ]; then
    $HOME/.local/bin/mise install
fi
