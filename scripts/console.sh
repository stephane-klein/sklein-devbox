#!/bin/bash
set -e

cd "$(dirname "$0")/.."

CONTAINER_ID=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
if [ -z "$CONTAINER_ID" ]; then
    mise run up
    CONTAINER_ID=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
fi
SSH_PORT=$(podman port ${CONTAINER_ID} 2222 | cut -d: -f2)

alacritty -e ssh -t \
    -i $(pwd)/.sklein-devbox-ssh-client-keys/id_ed25519 \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -p ${SSH_PORT} \
    sklein@localhost \
    "cd /workspace && /bin/zsh -i -c 'tmux new-session -A -s devbox'"
