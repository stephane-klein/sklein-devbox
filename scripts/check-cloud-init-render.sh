#!/usr/bin/env bash
set -euo pipefail

# Render templates/cloud-init.yaml.jinja with the real secrets and validate it.
# The secrets are resolved through fnox/gopass: the check-cloud-init task wraps
# this script in `fnox exec`, so they usually come from the environment (the
# fallbacks keep it runnable standalone).
#
# The rendered user-data only ever lives in shell variables and pipes: nothing
# is written to disk.

cd "$(dirname "$0")/.."

TEMPLATE="templates/cloud-init.yaml.jinja"
[ -f "$TEMPLATE" ] || { echo "error: $TEMPLATE not found" >&2; exit 1; }

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# --- Environment -------------------------------------------------------------

export NETBIRD_SETUP_KEY="${NETBIRD_SETUP_KEY:-$(gopass show -o netbird/setup-keys/incus-auto-group)}"
export NETBIRD_PAT="${NETBIRD_PAT:-$(fnox get NETBIRD_PAT)}"
export GOPASS_AGE_PASSWORD="${GOPASS_AGE_PASSWORD:-$(fnox get GOPASS_AGE_PASSWORD)}"
export SSH_STEPHANE_KLEIN_DEVBOX="${SSH_STEPHANE_KLEIN_DEVBOX:-$(fnox get SSH_STEPHANE_KLEIN_DEVBOX)}"
export SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_B64="${SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_B64:-${SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_BASE64:-$(fnox get SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_BASE64)}}"
export DEVBOX_SSH_CONFIG="$(cat sklein-devbox-mise-config/dotfiles/.ssh/config)"

# Exercise the git bootstrap block of the template.
export SKLEIN_DEVBOX_GIT_CLONE=1
export SKLEIN_DEVBOX_GIT_BRANCH="${SKLEIN_DEVBOX_GIT_BRANCH:-poc-reboot-to-incus-lxc-and-mise-bootstrap}"
export SKLEIN_DEVBOX_BOOTSTRAP=1

# --- Render and validate -----------------------------------------------------

rendered="$(minijinja-cli --strict --env "$TEMPLATE")"

printf '%s\n' "$rendered" | head -n1 | grep -qx '#cloud-config' \
  || fail "first line is not '#cloud-config'"
printf '%s\n' "$rendered" | yq e '.' - >/dev/null 2>&1 \
  || fail "rendered output is not valid YAML"

json="$(printf '%s\n' "$rendered" | yq e -o=json '.' -)"
has_path() { printf '%s' "$json" | jq -e --arg p "$1" 'any(.write_files[]?; .path==$p)' >/dev/null; }
get_content() { printf '%s' "$json" | jq -r --arg p "$1" '.write_files[] | select(.path==$p) | .content'; }

# Git bootstrap entry, run as devbox, on the expected branch.
printf '%s' "$json" | jq -e --arg br "$SKLEIN_DEVBOX_GIT_BRANCH" \
  'any(.runcmd[]?; type=="array" and .[0]=="su" and .[1]=="devbox"
       and (.[3] | contains("git clone --branch " + $br + " --single-branch")))' >/dev/null \
  || fail "runcmd is missing the git bootstrap entry"

# In-container bootstrap entry, run as devbox.
printf '%s' "$json" | jq -e \
  'any(.runcmd[]?; type=="array" and .[0]=="su" and .[1]=="devbox"
       and (.[3] | contains("bootstrap-sklein-devbox.sh")))' >/dev/null \
  || fail "runcmd is missing the in-container bootstrap entry"

# Always present.
has_path /tmp/netbird-setup-key || fail "netbird-setup-key entry missing"
has_path /tmp/netbird-api-token || fail "netbird-api-token entry missing"

# Presence-driven entries: each optional variable must match its entries.
if [ -n "${GOPASS_AGE_PASSWORD:-}" ]; then
  has_path /tmp/sklein-devbox-gopass-age-password || fail "passphrase entry missing"
  [ "$(get_content /tmp/sklein-devbox-gopass-age-password)" = "$GOPASS_AGE_PASSWORD" ] \
    || fail "passphrase not round-tripped correctly"
  printf '%s' "$json" | jq -e --arg p /tmp/sklein-devbox-gopass-age-password \
    '.write_files[] | select(.path==$p) | .owner == "devbox:devbox"' >/dev/null \
    || fail "passphrase entry not owned by devbox"
fi

if [ -n "${SSH_STEPHANE_KLEIN_DEVBOX:-}" ]; then
  get_content /home/devbox/.ssh/stephane-klein-devbox | grep -q 'PRIVATE KEY' \
    || fail "ssh private key not written as a multiline block"
fi

if [ -n "${SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_B64:-}" ]; then
  printf '%s' "$json" | jq -e --arg p /home/devbox/.config/gopass/age/identities \
    '.write_files[] | select(.path==$p) | .encoding == "b64"' >/dev/null \
    || fail "age identities not encoded as b64"
  [ "$(get_content /home/devbox/.config/gopass/age/identities)" = "$SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_B64" ] \
    || fail "age identities base64 value mismatch"
  has_path /home/devbox/.config/gopass/config || fail "gopass config entry missing"
fi

if [ -n "${DEVBOX_SSH_CONFIG:-}" ]; then
  has_path /home/devbox/.ssh/config || fail "ssh config entry missing"
fi

# --- Display -----------------------------------------------------------------

entries="$(printf '%s' "$json" | jq -r '.write_files | length')"
echo
echo "===== rendered cloud-init ($entries write_files) ====="
echo "WARNING: this output contains real secrets (passphrase, private key)."
printf '%s\n' "$rendered"
echo
echo "OK: cloud-init renders to valid YAML; no file written to disk"
