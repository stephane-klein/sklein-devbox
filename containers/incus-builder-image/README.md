# incus-builder job image

Container image used by the Forgejo Actions job that builds the
`sklein-devbox-dev` Incus LXC image with distrobuilder.

It is published to the private Forgejo container registry as
`forgejo.sklein.internal/stephane-klein/incus-builder-image:latest` and consumed
by [`.forgejo/workflows/build-lxc-image.yml`](../../.forgejo/workflows/build-lxc-image.yml)
through `container.image`, so the tools are installed once in the image instead
of on every job.

## Contents

- `node:24-bookworm` — the `node` runtime the Forgejo runner needs to execute
  JavaScript actions such as `actions/checkout`.
- `mise` (with Go installed globally) — installs `distrobuilder`, `rclone` and
  `incus-simplestreams` from the project `.mise.toml` at job time.
- distrobuilder build dependencies: `debootstrap`, `squashfs-tools`,
  `genisoimage`, `umoci`, `libgpgme-dev`, `libbtrfs-dev`, `gcc`.

## Build

Rebuild and push the image (manual, `workflow_dispatch`):

```sh
$ mise run create-forgejo-secrets       # once: creates the REGISTRY_TOKEN secret
$ mise run build-incus-builder-image
```

The workflow itself runs on `node:24-bookworm` with the docker client installed
on the fly, so its cost is only paid on the rare rebuilds of this image.
