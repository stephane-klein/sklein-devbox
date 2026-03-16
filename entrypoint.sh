#!/bin/bash
set -e

HOST_UID=$(stat -c %u /workspace 2>/dev/null || echo 1000)

if [ "$HOST_UID" != "1000" ]; then
    usermod -u "$HOST_UID" sklein
    groupmod -g "$HOST_UID" sklein
fi

# chown -R sklein:sklein /home/sklein

# [ ! -f /home/sklein/.zshrc ] && echo "# empty" > /home/sklein/.zshrc

if [ ! -d "/home/sklein/.local/share/chezmoi" ]; then
    gosu sklein chezmoi init https://github.com/stephane-klein/sklein-devbox-chezmoi.git
fi

if [ ! -d "~/.config/chezmoi/chezmoistate.boltdb" ]; then
    gosu sklein chezmoi apply
fi


exec gosu sklein "$@"
