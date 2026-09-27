#!/usr/bin/env bash
# ~/bin/export-gpg-keys.sh
set -euo pipefail

# --- Private keys → gopass ---
echo "==> Exporting private keys to gopass..."

PRIVATE_FINGERPRINTS=$(gpg --list-secret-keys --with-colons --fingerprint \
    | awk -F: '$1 == "fpr" { print $10 }')

if [[ -z "$PRIVATE_FINGERPRINTS" ]]; then
    echo "No secret keys found."
else
    for KEY_ID in $PRIVATE_FINGERPRINTS; do
        echo "  -> $KEY_ID"
        gpg --armor --export "$KEY_ID" \
            | gopass insert -f -m "gpg/keys/${KEY_ID}/public"
        gpg --armor --export-secret-keys "$KEY_ID" \
            | gopass insert -f -m "gpg/keys/${KEY_ID}/private"
        gpg --armor --export-secret-subkeys "$KEY_ID" \
            | gopass insert -f -m "gpg/keys/${KEY_ID}/private-subkeys"
    done
fi

# --- Public keys ---
echo ""
echo "==> Exporting public keys to chezmoi (~/.local/share/gopass/stores/root/gpg/pubkeys/)..."

mkdir -p ~/.local/share/gopass/stores/root/gpg/pubkeys/

PUBLIC_FINGERPRINTS=$(gpg --list-keys --with-colons --fingerprint \
    | awk -F: '$1 == "fpr" { print $10 }')

for KEY_ID in $PUBLIC_FINGERPRINTS; do
    echo "  -> $KEY_ID"
    gpg --armor --export "$KEY_ID" > ~/.local/share/gopass/stores/root/gpg/pubkeys/${KEY_ID}.asc
done

echo ""
echo "==> Public keys exported to: ~/.local/share/gopass/stores/root/gpg/pubkeys/"

(
  cd ~/.local/share/gopass/stores/root
  if ! git diff --quiet HEAD -- gpg/pubkeys/ || git ls-files --others --exclude-standard gpg/pubkeys/ | grep -q .; then
    git add gpg/pubkeys/
    git commit -m "Add gpg/pubkeys/"
    echo "==> Committed gpg/pubkeys/ changes."
  else
    echo "==> No changes in gpg/pubkeys/, skipping commit."
  fi
)
