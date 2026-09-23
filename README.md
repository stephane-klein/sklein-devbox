# sklein-devbox

> [!NOTE]
> You are viewing an experimental branch, a reboot of the *sklein-devbox* project toward
> [Incus LXC](https://linuxcontainers.org/incus/) and [Mise bootstrap](https://mise.jdx.dev/bootstrap.html).
> For now this branch is a POC that, if successful, will become the future stable version.

## AI-Assisted Development

This project was developed using:

- [OpenCode](https://opencode.ai) CLI — coding assistant workflow (not vibe coding)
- Models: DeepSeek-v4.1-Flash (OpenCode Go)

## Tech stack

- [Incus LXC](https://linuxcontainers.org/incus/)
- [Mise bootstrap](https://mise.jdx.dev/bootstrap.html)
- [mutagen](https://github.com/mutagen-io/mutagen) to sync project files from workstation to Incus LXC container

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

### Start and enter in sklein-devbox-dev LXC container

```sh
$ mise run incus-start-lxc
$ mise run ssh
[ssh] $ ssh devbox@sklein-devbox-dev.homelab.stephane-klein.info
Last login: Wed Sep 23 09:37:56 2026 from fd0e:5069:2174:137b:7db2:51cb:33f7:339
[devbox@sklein-devbox-dev ~]$ ls
workspace
```
