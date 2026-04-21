#!/bin/bash
set -e

cd "$(dirname "$0")/.."

EXISTING=$(podman ps --filter "label=app=sklein-devbox" --filter "label=sklein-devbox-pwd=$(pwd)" -q)
if [ -z "$EXISTING" ]; then
    echo "No container running"
    exit 0
fi

podman stop -t 30 ${EXISTING} && podman rm ${EXISTING}
echo "Container stopped"
