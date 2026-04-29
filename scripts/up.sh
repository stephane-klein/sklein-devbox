#!/bin/bash
set -e

cd "$(dirname "$0")/.."

mkdir -p ./.sklein-devbox-ssh-client-keys
if [ ! -f ./.sklein-devbox-ssh-client-keys/id_ed25519 ]; then
    ssh-keygen -t ed25519 -f ./.sklein-devbox-ssh-client-keys/id_ed25519 -N "" -q
fi

mkdir -p $(pwd)/.sklein-devbox-home
mkdir -p $(pwd)/.sklein-devbox-home/.local/share/chezmoi/
mkdir -p $(pwd)/.sklein-devbox-home/.config/gopass/age/
mkdir -p ~/.ssh/
mkdir -p ~/.config/gopass/
mkdir -p ~/.local/share/gopass/
mkdir -p $(pwd)/.sklein-devbox-ssh-host-keys

EXISTING=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
if [ -n "$EXISTING" ]; then
    echo "Container already running: $EXISTING"
    exit 0
fi

CONTAINER_ID=$(podman run -d \
    --userns=keep-id \
    --label=app=sklein-devbox \
    --label=sklein-devbox-pwd=$(pwd) \
    --cap-add=SETUID \
    --cap-add=SETGID \
    -e SKLEIN_DEVBOX_PWD=$(pwd) \
    -e TERM \
    -e SKLEIN_DEVBOX_NAME=sklein-devbox \
    -e SKLEIN_DEVBOX_GOPASS=1 \
    -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
    -v $(pwd):/workspace/:U \
    -v $(pwd)/.sklein-devbox-home/:/home/sklein/:U \
    -v $(pwd)/.sklein-devbox-ssh-host-keys:/var/lib/sklein-devbox/ssh-host-keys:U \
    -v $(pwd)/chezmoi/:/home/sklein/.local/share/chezmoi/:U \
    -v $(pwd)/chezmoi/sklein-devbox-init.sh:/usr/local/bin/sklein-devbox-init.sh:U \
    -v $(pwd)/chezmoi/ssh-forcecommand-entrypoint.sh:/usr/local/bin/ssh-forcecommand-entrypoint.sh:U \
    -v ~/.ssh/:/tmp/host-ssh/:ro \
    -v $(pwd)/.sklein-devbox-ssh-client-keys/id_ed25519.pub:/tmp/devbox-ssh-key.pub:ro \
    -v ~/.config/gopass/age/identities/:/home/sklein/.config/gopass/age/identities:U \
    -v ~/.local/share/gopass/:/home/sklein/.local/share/gopass/:U \
    -p 2222 \
    ghcr.io/stephane-klein/sklein-devbox:latest)

SSH_PORT=$(podman port ${CONTAINER_ID} 2222 | cut -d: -f2)

printf "Starting container... "
until ssh -i ./.sklein-devbox-ssh-client-keys/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/dev/null -o ConnectTimeout=1 -p ${SSH_PORT} sklein@localhost healthcheck 2>/dev/null; do
    printf "."
    sleep 0.5
done
echo "Container started: $CONTAINER_ID (port $SSH_PORT)"
