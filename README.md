# sklein-devbox

A personal, opinionated Podman-based development environment running Fedora 43.  
Designed to keep each project's toolchain and dependencies isolated.

## What's inside

- [mise](https://mise.jdx.dev) — runtime version manager
- [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) — editor
- [OpenCode](https://opencode.ai) — AI coding agent
- [Chezmoi](https://www.chezmoi.io/) — dotfiles manager (configuration stored in
  [sklein-devbox-chezmoi](https://github.com/stephane-klein/sklein-devbox-chezmoi))


## Getting started

Install sklein-devbox via Fedora COPR:

```sh
$ sudo dnf copr enable stephaneklein/sklein-devbox
$ sudo dnf install sklein-devbox
$ sklein-devbox --version
sklein-devbox version 20260318.0.0-d6b0178
```

Then enter your development environment from your project directory:

```sh
$ cd ~/git/github/stephane-klein/myproject/
$ sklein-devbox enter
➜  /workspace git:(main) ✗ exit
$ ./sklein-devbox list
default  /home/stephane/.local/share/sklein-devbox/default
```

For a better terminal experience, use the `console` command which opens an
[Alacritty](https://alacritty.org/) terminal with tmux pre-configured:

```sh
$ sklein-devbox console
```

> [!NOTE]
> Why two commands? `enter` vs `console`
>
> If you already run tmux on your host machine, the `enter` command
> would nest sessions, which is not ideal. The `console` command solves this by
> running tmux in a new Alacritty instance.

## Persistence and dotfiles management

The container persists user data in `~/.local/share/sklein-devbox/<name>`
(the default name is `default`). This directory is bind-mounted to
`/home/sklein` inside the container. Your changes—including shell history,
Zsh customizations, and configuration files—are saved on your host workstation.

[Chezmoi](https://www.chezmoi.io/) manages dotfiles inside the container,
synchronized from a remote repository.

**Multiple instances:** Use `--name` to create isolated environments:

```sh
$ sklein-devbox --name=project-a enter   # Uses ~/.local/share/sklein-devbox/project-a
$ sklein-devbox --name=project-b enter   # Uses ~/.local/share/sklein-devbox/project-b
```

*Configuration:* You can configure the instance name using a `.sklein-devbox.toml` file in your project directory:

```toml
name = "myinstancename"
```

Or use the `SKLEIN_DEVBOX_NAME` environment variable:

```sh
$ SKLEIN_DEVBOX_NAME=myinstancename sklein-devbox enter
```

Configuration priority (highest to lowest): command line flag → environment variable → config file → default value ("default").

**Reset environment:** Delete the instance directory:

```sh
$ sklein-devbox --name=default destroy    # Removes ~/.local/share/sklein-devbox/default
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, versioning, and release workflow.
