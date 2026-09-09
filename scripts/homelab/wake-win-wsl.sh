#!/usr/bin/env bash
# =============================================================================
# File: scripts/homelab/wake-win-wsl.sh
# Purpose: Send a Wake-on-LAN magic packet to power on the Windows/WSL
#          machine (often fully off, not just asleep) from this MBP. Run
#          this BEFORE start-wsl-k3s-worker.ps1 can do anything, since no
#          script running on that machine can power itself on. Tracked
#          under issue #1922.
#
# One-time prerequisites on the Windows machine (BIOS/UEFI setting, not
# something this script can do remotely):
#   1. BIOS/UEFI: enable "Wake on LAN" / "Power On by PCI-E/PCIE"
#   2. Windows: Device Manager -> network adapter -> Power Management ->
#      check "Allow this device to wake the computer" and, under Advanced,
#      enable "Wake on Magic Packet"
#   3. Disable "Fast Startup" (Control Panel -> Power Options) - it can
#      prevent WOL from working after a shutdown on some hardware
# =============================================================================
set -euo pipefail

MAC="e4:c7:67:f0:da:43" # win-wsl (192.168.1.13), from arp -a
BROADCAST="192.168.1.255"

python3 -c "
import socket
mac = '$MAC'.replace(':', '')
packet = bytes.fromhex('FF' * 6 + mac * 16)
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
s.sendto(packet, ('$BROADCAST', 9))
print('Magic packet sent to $MAC via $BROADCAST:9')
"

echo "Waiting for the machine to boot (this can take 30-90s)..."
