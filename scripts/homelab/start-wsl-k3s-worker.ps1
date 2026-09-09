# =============================================================================
# File: scripts/homelab/start-wsl-k3s-worker.ps1
# Purpose: Start WSL and join its Ubuntu guest to the homelab k3s cluster
#          (server currently running on the Mac Mini, 192.168.1.12) as a
#          worker node. Tracked under issue #1922 (multi-machine local k8s
#          pool: MBP client + Mac Mini server + this Windows/WSL worker +
#          Synology NAS storage).
#
# Idempotent - safe to run on every Windows startup (pair with the .bat
# wrapper, which self-elevates and calls this script, matching the
# k8sUp.ps1/.bat pattern already in use on this machine).
#
# Prerequisite (one-time): run prepare-wsl-connections.ps1 first so the WSL
# guest is reachable on the LAN.
#
# The join token is a cluster credential - never hardcode it here (this repo
# is public). Set it once via a persistent user env var before first run:
#   setx FAWKES_K3S_TOKEN "<token from: ssh mac-mini limactl shell k3s-worker -- sudo cat /var/lib/rancher/k3s/server/node-token>"
# =============================================================================

#Requires -RunAsAdministrator

$K3sUrl = "https://192.168.1.12:6443"
$K3sToken = $env:FAWKES_K3S_TOKEN
$Distro = "Ubuntu"

if (-not $K3sToken) {
    Write-Error "FAWKES_K3S_TOKEN is not set. Run: setx FAWKES_K3S_TOKEN `"<token>`" then open a new shell."
    exit 1
}

Write-Host "== Starting WSL ($Distro) =="
wsl -d $Distro -- true

Write-Host "== Joining k3s cluster at $K3sUrl =="
$joinScript = @"
if command -v k3s-agent >/dev/null 2>&1 || command -v k3s >/dev/null 2>&1; then
    echo 'k3s agent already installed, ensuring it is running...'
    sudo systemctl start k3s-agent 2>/dev/null || sudo /etc/init.d/k3s-agent start 2>/dev/null || true
else
    curl -sfL https://get.k3s.io | K3S_URL='$K3sUrl' K3S_TOKEN='$K3sToken' sh -s - agent
fi
"@

wsl -d $Distro -- bash -c $joinScript

Write-Host "== Done. Verify from the Mac Mini or MBP with: kubectl get nodes =="
