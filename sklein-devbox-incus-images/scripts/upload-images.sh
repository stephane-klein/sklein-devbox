#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../"

for f in \
  dist/sklein-devbox-dev/incus.tar.xz \
  dist/sklein-devbox-dev/rootfs.squashfs; do
  test -f "$f" || { echo "ERROR: missing $f (run build-lxc)" >&2; exit 1; }
done

rm -rf .simplestreams && mkdir -p .simplestreams
(
  cd .simplestreams
  incus-simplestreams add --alias sklein-devbox-dev \
    ../dist/sklein-devbox-dev/incus.tar.xz \
    ../dist/sklein-devbox-dev/rootfs.squashfs
)

# Credentials come from the environment when provided (CI: Forgejo Actions
# secrets), otherwise fall back to gopass (workstation).
export RCLONE_S3_ACCESS_KEY_ID="${SCW_ACCESS_KEY:-$(gopass show -o homelab/incus-images/SCW_ACCESS_KEY)}"
export RCLONE_S3_SECRET_ACCESS_KEY="${SCW_SECRET_KEY:-$(gopass show -o homelab/incus-images/SCW_SECRET_KEY)}"

rclone sync .simplestreams/ :s3:incus-images \
  --s3-provider Scaleway \
  --s3-endpoint https://s3.fr-par.scw.cloud \
  --s3-region fr-par \
  --s3-acl public-read \
  --log-level ERROR \
  --progress
