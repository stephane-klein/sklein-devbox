#!/bin/bash
set -e

cd "$(dirname "$0")/.."

CONTAINER_ID=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
if [ -z "$CONTAINER_ID" ]; then
    mise run up
    CONTAINER_ID=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
fi

SSH_PORT=$(podman inspect --format '{{index .Config.Labels "sklein-devbox-ssh-port"}}' ${CONTAINER_ID})

# Each console opens its own grouped tmux session named "devbox-<remote-sh-PID>":
# $$ expands to the PID of the remote sh process, giving a unique name per console.
# Sessions in the "devbox" group share the same windows, but each keeps its own
# current window, so every console can display a different window independently.
# "destroy-unattached on" deletes the per-console session when its console closes.
foot -e ssh -t \
    -i $(pwd)/.sklein-devbox-ssh-client-keys/id_ed25519 \
    -o StrictHostKeyChecking=accept-new \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o SetEnv=SKLEIN_DEVBOX_DISABLE_INIT=1 \
    -p ${SSH_PORT} \
    sklein@localhost \
    "sh -c 'cd /workspace && { tmux has-session -t devbox 2>/dev/null || tmux new-session -d -s devbox; } && exec tmux new-session -d -t devbox -s devbox-\$\$ \; set-option -t devbox-\$\$ destroy-unattached on \; attach-session -t devbox-\$\$'"
