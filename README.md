# sklein-devbox

A personal, opinionated Podman-based development environment running Fedora 43.  
Designed to keep each project's toolchain and dependencies isolated.

## What's inside

- [mise](https://mise.jdx.dev) — runtime version manager
- [Neovim](https://neovim.io) + [LazyVim](https://lazyvim.org) — editor
- [OpenCode](https://opencode.ai) — AI coding agent

## Getting started

```sh
$ mise run build

[...]

$ mise run enter
[root@0b7199cc717c]/workspace# cat /etc/os-release
NAME="Fedora Linux"
VERSION="43 (Container Image)"
RELEASE_TYPE=stable
ID=fedora
VERSION_ID=43
VERSION_CODENAME=""
PRETTY_NAME="Fedora Linux 43 (Container Image)"
ANSI_COLOR="0;38;2;60;110;180"
LOGO=fedora-logo-icon
CPE_NAME="cpe:/o:fedoraproject:fedora:43"
DEFAULT_HOSTNAME="fedora"
HOME_URL="https://fedoraproject.org/"
DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f43/"
SUPPORT_URL="https://ask.fedoraproject.org/"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_BUGZILLA_PRODUCT="Fedora"
REDHAT_BUGZILLA_PRODUCT_VERSION=43
REDHAT_SUPPORT_PRODUCT="Fedora"
REDHAT_SUPPORT_PRODUCT_VERSION=43
SUPPORT_END=2026-12-02
VARIANT="Container Image"
VARIANT_ID=container
[root@0b7199cc717c]/workspace# mise --version
              _                                        __
   ____ ___  (_)_______        ___  ____        ____  / /___ _________
  / __ `__ \/ / ___/ _ \______/ _ \/ __ \______/ __ \/ / __ `/ ___/ _ \
 / / / / / / (__  )  __/_____/  __/ / / /_____/ /_/ / / /_/ / /__/  __/
/_/ /_/ /_/_/____/\___/      \___/_/ /_/     / .___/_/\__,_/\___/\___/
                                            /_/                 by @jdx
2026.3.8 linux-x64 (2026-03-11)
[root@0b7199cc717c]/workspace#
```
