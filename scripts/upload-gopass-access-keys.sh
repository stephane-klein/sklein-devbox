#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

HOST="devbox@sklein-devbox-dev.homelab.stephane-klein.info"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf '%s\n' "$SSH_STEPHANE_KLEIN_DEVBOX" > "$TMP/stephane-klein-devbox"
printf '%s' "$SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_BASE64" | base64 -d > "$TMP/age-identities"
test -s "$TMP/age-identities"
printf '%s' "$GOPASS_AGE_PASSWORD" > "$TMP/gopass-age-password"
test -s "$TMP/gopass-age-password"

ssh "$HOST" 'install -d -m 700 ~/.ssh ~/.config/gopass/age && rm -rf /tmp/gopass-access-keys && mkdir -m 700 /tmp/gopass-access-keys'
scp -q "$TMP/stephane-klein-devbox" "$TMP/age-identities" "$TMP/gopass-age-password" sklein-devbox-mise-config/dotfiles/.ssh/config "$HOST:/tmp/gopass-access-keys/"
ssh "$HOST" 'install -m 600 /tmp/gopass-access-keys/stephane-klein-devbox ~/.ssh/stephane-klein-devbox && install -m 600 /tmp/gopass-access-keys/age-identities ~/.config/gopass/age/identities && install -m 600 /tmp/gopass-access-keys/config ~/.ssh/config && install -m 600 /tmp/gopass-access-keys/gopass-age-password /tmp/sklein-devbox-gopass-age-password && rm -rf /tmp/gopass-access-keys'

ssh "$HOST" 'umask 077; cat > ~/.config/gopass/config <<EOF
[mounts]
        path = $HOME/.local/share/gopass/stores/root
[recipients]
        hash = 3ee561c30c8c84a3462a2c948d4595c3e1ff122ed42e43f74c9086b5d9ffce30
[age]
        agent-timeout = 604800
        agent-enabled = true
[core]
        auto = false
        autopush = false
EOF'
