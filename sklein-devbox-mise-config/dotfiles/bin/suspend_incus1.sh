#!/usr/bin/env bash
# ~/bin/suspend_incus-server1.sh
# Suspend the incus-server1 host (Fedora CoreOS) via SSH.
set -euo pipefail

ssh -t stephane@incus-server1.homelab.stephane-klein.info sudo systemctl suspend
