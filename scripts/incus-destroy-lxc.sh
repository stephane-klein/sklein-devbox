#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

mutagen project terminate || true

NETBIRD_API="https://api.netbird.io/api"
PEER_HOST="sklein-devbox-dev"
PEER_FQDN="sklein-devbox-dev.homelab.stephane-klein.info"

if NETBIRD_PAT="$(fnox get NETBIRD_PAT 2>/dev/null)"; then
  PEERS_JSON="$(curl -fsS -H "Authorization: Token ${NETBIRD_PAT}" "${NETBIRD_API}/peers" || true)"
  PEER_IDS="$(printf '%s' "${PEERS_JSON}" \
    | jq -r --arg h "${PEER_HOST}" --arg f "${PEER_FQDN}" \
        '.[]? | select(.name==$h or .hostname==$h or .dns_label==$h or .name==$f or .hostname==$f or .dns_label==$f) | .id')"

  if [ -z "${PEER_IDS}" ]; then
    echo "No NetBird peer matching '${PEER_HOST}' found."
  else
    for id in ${PEER_IDS}; do
      echo "Deleting NetBird peer ${id}..."
      curl -fsS -o /dev/null -X DELETE -H "Authorization: Token ${NETBIRD_PAT}" "${NETBIRD_API}/peers/${id}" \
        && echo "  done." || echo "  failed (ignored)." >&2
    done
  fi
else
  echo "NETBIRD_PAT unavailable, skipping NetBird peer cleanup." >&2
fi

if incus info sklein-devbox-dev >/dev/null 2>&1; then
  incus delete --force sklein-devbox-dev
  echo "Instance 'sklein-devbox-dev' destroyed."
else
  echo "Instance 'sklein-devbox-dev' does not exist."
fi
