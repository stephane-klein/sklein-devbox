#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# Set SKLEIN_DEVBOX_VERBOSE=1 to trace every command.
if [ -n "${SKLEIN_DEVBOX_VERBOSE:-}" ]; then
  set -x
fi

# Git bootstrap mode is enabled by SKLEIN_DEVBOX_GIT_CLONE: cloud-init clones
# the repository into the container on first boot, and mutagen is disabled
# (the git working tree becomes the source of truth).
if [ -n "${SKLEIN_DEVBOX_GIT_CLONE:-}" ]; then
  export SKLEIN_DEVBOX_GIT_BRANCH="${SKLEIN_DEVBOX_GIT_BRANCH:-poc-reboot-to-incus-lxc-and-mise-bootstrap}"
fi

if incus info sklein-devbox-dev >/dev/null 2>&1; then
  # cloud-init only runs on first boot: a clone cannot happen on an existing
  # instance. Fail loudly rather than silently skip the bootstrap.
  if [ -n "${SKLEIN_DEVBOX_GIT_CLONE:-}" ] \
     && ! incus exec sklein-devbox-dev -- test -d /home/devbox/.local/share/sklein-devbox/.git 2>/dev/null; then
    echo "ERROR: instance 'sklein-devbox-dev' already exists without a git tree;" >&2
    echo "cloud-init won't re-run the clone. Run 'mise run incus-destroy-lxc' first." >&2
    exit 1
  fi
  echo "Instance 'sklein-devbox-dev' already exists, skipping creation."
else
  # Incus reuses the cached simplestreams image without checking the remote.
  # Delete the cached copy to force a fresh download of the latest published
  # version on the following incus create.
  for fingerprint in $(incus image list --format json \
        | jq -r '.[] | select(.update_source.alias == "sklein-devbox-dev") | .fingerprint'); do
    incus image delete "$fingerprint"
  done

  export NETBIRD_SETUP_KEY="$(gopass show -o netbird/setup-keys/incus-auto-group)"
  export NETBIRD_PAT="${NETBIRD_PAT:-$(fnox get NETBIRD_PAT)}"

  # Optional gopass access material, injected into cloud-init by
  # templates/cloud-init.yaml.jinja when present in the environment. The
  # secrets themselves come from `fnox exec` (see the incus-start-lxc task).
  # The age keyring is already base64-encoded in fnox.
  export SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_B64="${SKLEIN_DEVBOX_SECRETS_AGE_KEYRING_BASE64:-}"
  export DEVBOX_SSH_CONFIG="$(cat sklein-devbox-mise-config/dotfiles/.ssh/config)"

  # The rendered user-data is kept in a shell variable only: it is never
  # written to disk.
  cloud_init="$(minijinja-cli --strict --env templates/cloud-init.yaml.jinja)"

  incus create sklein:sklein-devbox-dev sklein-devbox-dev \
    --profile default \
    --config security.nesting=true \
    --config cloud-init.user-data="$cloud_init"
fi

if [ "$(incus list sklein-devbox-dev -c s --format csv)" = "RUNNING" ]; then
  echo "Instance 'sklein-devbox-dev' is already running."
else
  incus start sklein-devbox-dev
fi

# After recreation, the NetBird peer gets a new IP but MagicDNS keeps
# the old answer cached (TTL ~5 min). Wait for the FQDN to point
# to the current container before continuing.
DEVBOX_FQDN="sklein-devbox-dev.homelab.stephane-klein.info"
echo "==> Waiting for NetBird DNS to publish the new container (TTL ~5 min)..."
RESOLVED_IPV4=""
CONTAINER_IPV4=""
for i in $(seq 1 180); do
  if RESOLVED_IPV4="$(getent ahostsv4 "$DEVBOX_FQDN" 2>/dev/null | awk 'NR==1{print $1}')" \
     && CONTAINER_IPV4="$(incus exec sklein-devbox-dev -- ip -4 -o addr show wt0 2>/dev/null | awk 'NR==1{print $4}' | cut -d/ -f1)" \
     && [ -n "$RESOLVED_IPV4" ] && [ "$RESOLVED_IPV4" = "$CONTAINER_IPV4" ]; then
    break
  fi
  if [ $((i % 10)) -eq 0 ]; then
    echo "  ... waiting (resolved=${RESOLVED_IPV4:-none} container=${CONTAINER_IPV4:-none})"
  fi
  sleep 2
done
if [ -z "$RESOLVED_IPV4" ] || [ "$RESOLVED_IPV4" != "$CONTAINER_IPV4" ]; then
  echo "ERROR: $DEVBOX_FQDN resolves to '${RESOLVED_IPV4:-none}' but container is '${CONTAINER_IPV4:-none}'" >&2
  echo "--- netbird status in the container ---" >&2
  incus exec sklein-devbox-dev -- netbird status >&2 2>&1 || true
  exit 1
fi
echo "==> DNS OK: $DEVBOX_FQDN -> $RESOLVED_IPV4"

# The recreated container has new SSH host keys.
echo "==> Refreshing SSH host keys for $DEVBOX_FQDN..."
ssh-keygen -R "$DEVBOX_FQDN" >/dev/null 2>&1 || true
for _ in $(seq 1 30); do
  if KEYS="$(ssh-keyscan -t rsa,ecdsa,ed25519 "$DEVBOX_FQDN" 2>/dev/null)" && [ -n "$KEYS" ]; then
    printf '%s\n' "$KEYS" >> ~/.ssh/known_hosts
    break
  fi
  sleep 2
done

# In git bootstrap mode the clone and the in-container bootstrap run during
# cloud-init: wait for it and make sure the working tree actually exists before
# going further. A cloud-init error makes `cloud-init status --wait` exit
# non-zero; dump the log so the failure is actionable.
if [ -n "${SKLEIN_DEVBOX_GIT_CLONE:-}" ]; then
  echo "==> Waiting for cloud-init (git clone + in-container bootstrap)..."
  if ! incus exec sklein-devbox-dev -- cloud-init status --wait; then
    echo "ERROR: cloud-init failed. tail of /var/log/cloud-init-output.log:" >&2
    incus exec sklein-devbox-dev -- tail -n 100 /var/log/cloud-init-output.log >&2 || true
    exit 1
  fi
  if ! incus exec sklein-devbox-dev -- test -d /home/devbox/.local/share/sklein-devbox/.git; then
    echo "ERROR: git bootstrap did not create /home/devbox/.local/share/sklein-devbox/.git" >&2
    exit 1
  fi
  echo "==> cloud-init done. Cloned commit:"
  incus exec sklein-devbox-dev -- git -c safe.directory=/home/devbox/.local/share/sklein-devbox \
    -C /home/devbox/.local/share/sklein-devbox log --oneline -1 || true
fi

echo "==> Configuring mutagen..."
mutagen project terminate >/dev/null 2>&1 || true

# A git working tree means the container was bootstrapped from git: mutagen
# must not synchronize over it.
if incus exec sklein-devbox-dev -- test -d /home/devbox/.local/share/sklein-devbox/.git; then
  echo "git working tree detected — mutagen skipped."
else
  mutagen project start
fi

echo
echo "✓ sklein-devbox-dev is ready — enter it with: mise run ssh"
