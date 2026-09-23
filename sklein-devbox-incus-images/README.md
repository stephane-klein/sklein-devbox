# sklein-devbox LXC image powered for Incus

## Development

This section is intended for contributors working on the project (not end users).

### Prerequisites

- [Mise](https://mise.jdx.dev/) must be installed.

### Setup

Install the project tooling:

```sh
$ mise install
```

Build `sklein-devbox-dev` LXC image:

```sh
$ mise run build-lxc
$ mise run upload-images
```

## Forgejo Actions (CI)

The `.forgejo/workflows/build-lxc-image.yml` workflow builds the image and
publishes it to the Scaleway S3 `incus-images` bucket. It is triggered manually
through `workflow_dispatch`, from the repository root with
`mise run build-lxc-image`.

- It runs on the self-hosted Forgejo runner (`runs-on: ubuntu-latest`) inside the
  custom `forgejo.sklein.internal/stephane-klein/incus-builder-image` job
  container (node, Mise and the distrobuilder build dependencies). See
  [`../containers/incus-builder-image/`](../containers/incus-builder-image/).
- The job container must run **privileged** on a **rootful** podman engine:
  `distrobuilder` needs `mount`/`mknod`, impossible in an unprivileged container
  or with rootless podman (see the homelab `apps/forgejo/runner` README).
- In a job container neither systemd nor sudo is available, so `build-lxc.sh`
  runs `distrobuilder` directly (on a workstation it keeps the `systemd-run`
  cgroup scope). This works because the runner launches the job container with
  `--privileged`.
- The Scaleway credentials are read from the `SCW_ACCESS_KEY` / `SCW_SECRET_KEY`
  environment variables when set (Forgejo Actions secrets), and fall back to
  gopass otherwise. Create them with:

  ```sh
  $ mise run create-forgejo-secrets
  ```

- The `MISE_GITHUB_TOKEN` secret (a GitHub fine-grained token with read-only
  access to public repositories) lets Mise resolve the `github:` tools
  (`incus`, `rclone`, `minijinja`) against `api.github.com`. Without it, Mise
  would pick up the Forgejo `GITHUB_TOKEN` of the run — a token meant for
  Forgejo, rejected by GitHub (401). Create the token in the GitHub UI
  (*Public repositories (read-only)*, `Contents: Read-only`), store it in gopass
  at `github/mise-ci-readonly`, then run `mise run create-forgejo-secrets`.

- The `REGISTRY_TOKEN` repository secret is also required to publish the job
  image; `mise run create-forgejo-secrets` creates it (see
  [`../containers/incus-builder-image/`](../containers/incus-builder-image/)).
