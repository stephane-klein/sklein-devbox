#!/bin/bash
set -e

HOST_UID=$(stat -c %u /workspace 2>/dev/null || echo 1000)

if [ "$HOST_UID" != "1000" ]; then
    usermod -u "$HOST_UID" sklein
    groupmod -g "$HOST_UID" sklein
fi

chown -R sklein:sklein /home/sklein

# [ ! -f /home/sklein/.zshrc ] && echo "# empty" > /home/sklein/.zshrc

# Configure chezmoi source directory if environment variable is set
if [ -n "$CHEZMOI_SOURCE_DIR" ]; then
    mkdir -p /home/sklein/.config/chezmoi
    echo "sourceDir = \"${CHEZMOI_SOURCE_DIR}\"" > /home/sklein/.config/chezmoi/chezmoi.toml
    chown -R sklein:sklein /home/sklein/.config/chezmoi
else
  if [ ! -d "/home/sklein/.local/share/chezmoi" ]; then
      gosu sklein chezmoi init https://github.com/stephane-klein/sklein-devbox.git
  fi
fi

if [ ! -d "~/.config/chezmoi/chezmoistate.boltdb" ]; then
    gosu sklein chezmoi apply
fi


exec gosu sklein "$@"
