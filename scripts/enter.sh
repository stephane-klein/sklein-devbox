#!/bin/bash
set -e

cd "$(dirname "$0")/.."

CONTAINER_ID=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
if [ -z "$CONTAINER_ID" ]; then
    echo "Error: No container running. Run 'mise run up' first." >&2
    exit 1
fi

SSH_PORT=$(podman inspect --format '{{index .Config.Labels "sklein-devbox-ssh-port"}}' ${CONTAINER_ID})
ssh -t \
    -i $(pwd)/.sklein-devbox-ssh-client-keys/id_ed25519 \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -p ${SSH_PORT} \
    sklein@localhost \
    "cd /workspace && exec /bin/zsh -i"
