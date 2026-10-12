#!/bin/sh

set -e

COMMAND=${1:-""}

case "$COMMAND" in
    migrate)
        node src/migrate.js
        ;;
    seed)
        node src/migrate.js
        node src/seed.js
        ;;
    hello|"")
        node src/migrate.js
        node src/hello_world.js
        ;;
    *)
        exec "$@"
        ;;
esac