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
