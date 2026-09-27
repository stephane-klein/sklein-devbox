#!/usr/bin/env bash
# ~/bin/import-gpg-keys.sh
# Import all GPG keys from gopass

set -euo pipefail

export GNUPGHOME="${HOME}/.config/gnupg"

mkdir -p "${GNUPGHOME}"
chmod 700 "${GNUPGHOME}"

# --- 1. Import public keys from ~/.config/gnupg/pubkeys/ ---
PUBKEYS_DIR="${HOME}/.local/share/gopass/stores/root/gpg/pubkeys/"

if [[ -d "$PUBKEYS_DIR" ]]; then
    echo "==> Importing public keys from ${PUBKEYS_DIR}..."
    for ASC_FILE in "${PUBKEYS_DIR}"/*.asc; do
        [[ -f "$ASC_FILE" ]] || continue
        echo "    Importing $(basename "$ASC_FILE")..."
        gpg --import "$ASC_FILE"
    done
else
    echo "No pubkeys directory found at ${PUBKEYS_DIR}, skipping."
fi

# --- 2. Import private keys from gopass ---
echo "==> Listing keys available in gopass..."
gopass ls gpg/keys/

# Extract fingerprints from gopass tree
FINGERPRINTS=$(gopass ls --flat gpg/keys/ \
    | grep '/public$' \
    | sed 's|gpg/keys/||; s|/public||')

if [[ -z "$FINGERPRINTS" ]]; then
    echo "No keys found under gpg/keys/ in gopass. Aborting."
    exit 1
fi

for KEY_ID in $FINGERPRINTS; do
    echo ""
    echo "==> Importing key: ${KEY_ID}"

    echo "    Importing public key..."
    gopass show "gpg/keys/${KEY_ID}/private" | gpg --pinentry-mode loopback --import

    echo "    Importing private key..."
    gopass show "gpg/keys/${KEY_ID}/private-subkeys" | gpg --pinentry-mode loopback --import

    echo "    Done."
done

echo ""
echo "==> All keys imported. Current keyring:"
gpg --list-secret-keys --keyid-format=long
