# Project Goal

This project provides a portable and reproducible development environment, named here sklein-devbox.  
It consists of two main parts:

- A Podman container image (based on Fedora) that contains a complete development environment.  
  The home configuration is managed by Chezmoi, and tools are installed via Mise.
- A Go CLI (`sklein-devbox`) that allows instantiating containers based on this image. The home directory of these 
  environments is persistent, allowing data and configurations to be preserved between sessions.

# Image Reference

This project uses **Podman**, not Docker.

## Container Image

- **Name**: `sklein-devbox`
- **Base**: Fedora 43
- **Tools**: Mise, Zsh, Neovim

## Build

```bash
$ mise run build
```

## Run

```bash
$ mise run enter
```
