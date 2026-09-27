#!/usr/bin/env bash
# ~/bin/lock-ssh-agent.sh
set -euo pipefail

SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-/tmp/ssh-agent.sock}" ssh-add -D
