#!/usr/bin/env bash
set -euo pipefail

cp ~/.local/share/opencode/auth.json2 ~/.local/share/opencode/auth.json

pitchfork restart global/opencode-server

echo "opencode auth switched to account 2"
