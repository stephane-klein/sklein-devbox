#!/usr/bin/env bash
# ~/bin/wakeup_incus1.sh
# Send a Wake-on-LAN magic packet to incus1 via the nuc-i7-gen11 gateway.
set -euo pipefail

ssh stephane@nuc-i7-gen11.homelab.stephane-klein.info python3 - <<'PYEOF'
import socket

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
mac = bytes.fromhex('4ce17347af2f')
s.sendto(b'\xff' * 6 + mac * 16, ('192.168.1.255', 9))
PYEOF
