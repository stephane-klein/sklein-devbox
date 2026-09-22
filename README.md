# sklein-devbox

> [!NOTE]
> You are viewing an experimental branch, a reboot of the *sklein-devbox* project toward
> [Incus LXC](https://linuxcontainers.org/incus/) and [Mise bootstrap](https://mise.jdx.dev/bootstrap.html).
> For now this branch is a POC that, if successful, will become the future stable version.

## AI-Assisted Development

This project was developed using:

- [OpenCode](https://opencode.ai) CLI — coding assistant workflow (not vibe coding)
- Models: DeepSeek-v4.1-Flash (OpenCode Go)

## Getting started

Before continuing, the `sklein-devbox-dev` image must be available in the Incus image
registry.

```sh
$ mise run incus-list-images
+--------------------------+--------------+-----------+-----------+
|         ALIASES          | FINGERPRINT  |   TYPE    |   SIZE    |
+--------------------------+--------------+-----------+-----------+
| fedora/44/cloud          | 2f28d4bab4d1 | CONTAINER | 218.51MiB |
| fedora/44/cloud/x86_64   |              |           |           |
| sklein-devbox-dev        |              |           |           |
| sklein-devbox-dev/x86_64 |              |           |           |
+--------------------------+--------------+-----------+-----------+
```

To create or update this image, follow the instructions in [`./sklein-devbox-incus-images/`](./sklein-devbox-incus-images/).
