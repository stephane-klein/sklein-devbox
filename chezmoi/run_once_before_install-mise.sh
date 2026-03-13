#!/bin/bash
if [ ! -f "$HOME/.local/bin/mise" ]; then
    curl https://mise.run | sh
fi
