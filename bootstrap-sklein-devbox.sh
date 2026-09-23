#!/usr/bin/env bash
set -e

# In the container, the mise config lives in the sklein-devbox-mise-config/
# subdirectory of the cloned repository.
CONFIG_DIR="${SKLEIN_DEVBOX_CONFIG_DIR:-$HOME/.local/share/sklein-devbox/sklein-devbox-mise-config}"

# Load the gopass age passphrase (file dropped by cloud-init or by
# upload-gopass-access-keys.sh), then remove the file.
if [ -z "${GOPASS_AGE_PASSWORD:-}" ] && [ -f /tmp/sklein-devbox-gopass-age-password ]; then
  export GOPASS_AGE_PASSWORD="$(cat /tmp/sklein-devbox-gopass-age-password)"
fi
rm -f /tmp/sklein-devbox-gopass-age-password

sudo dnf install -y git

install -d -m 700 ~/.ssh
touch ~/.ssh/known_hosts
grep -v -E '^github\.com ' ~/.ssh/known_hosts > ~/.ssh/known_hosts.new || true
curl -fsSL https://api.github.com/meta \
  | jq -r '.ssh_keys[]' \
  | sed 's/^/github.com /' \
  >> ~/.ssh/known_hosts.new
mv ~/.ssh/known_hosts.new ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

# Install Mise
curl https://mise.run | sh

# Add Mise shell activation, driven by the synced mise.toml
[ -f "$CONFIG_DIR/mise.toml" ] || {
  echo "error: $CONFIG_DIR/mise.toml not found (is mutagen sync running?)" >&2
  exit 1
}

~/.local/bin/mise trust "$CONFIG_DIR/mise.toml"
~/.local/bin/mise -C "$CONFIG_DIR" bootstrap mise-shell-activate apply --yes

~/.local/bin/mise use -g age gopass fnox

# fnox's `password-store` provider shells out to `pass`; gopass is a
# drop-in replacement, so expose the mise-installed gopass binary as `pass`.
# The `latest` alias is maintained by mise across gopass version upgrades.
install -d ~/.local/bin
ln -sf ~/.local/share/mise/installs/gopass/latest/gopass ~/.local/bin/pass

# Verify Mise activation in the current (non-interactive) shell
eval "$(~/.local/bin/mise activate bash)"
eval "$(~/.local/bin/mise hook-env)"
~/.local/bin/mise doctor

export PATH="$HOME/.local/bin:$PATH" # set here so fnox can reach pass (a symlink to gopass)

# fnox resolves the bootstrap secrets from the gopass store. Populate it on the
# first run: the repository holds both the encrypted secrets and the store
# configuration (.gopass/, .age-recipients). Access relies on the SSH key and
# the age identities dropped by cloud-init or upload-gopass-access-keys.sh.
STORE_ROOT="$HOME/.local/share/gopass/stores/root"
if [ ! -d "$STORE_ROOT/.git" ]; then
  mkdir -p "$(dirname "$STORE_ROOT")"
  git clone git@github.com:stephane-klein/sklein-devbox-secrets.git "$STORE_ROOT"
fi

fnox -c "$CONFIG_DIR/fnox.toml" exec -- mise -C "$CONFIG_DIR" bootstrap --yes
