#!/bin/bash
set -e

cd "$(dirname "$0")/.."

CONTAINER_ID=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
if [ -z "$CONTAINER_ID" ]; then
    echo "container is down"
    exit 0
fi

SSH_PORT=$(podman port ${CONTAINER_ID} 2222 2>/dev/null | cut -d: -f2)
UPTIME=$(podman inspect --format '{{.State.StartedAt}}' ${CONTAINER_ID})
echo "container is up"
echo "  Container: $CONTAINER_ID"
echo "  Port: ${SSH_PORT:-unknown}"
echo "  Started: $UPTIME"
