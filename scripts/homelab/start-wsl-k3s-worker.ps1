# =============================================================================
# File: scripts/homelab/start-wsl-k3s-worker.ps1
# Purpose: One idempotent "the machine just turned on" script - checks and
#          fixes network mode, SSH, and k3s cluster membership for the WSL
#          Ubuntu guest, in that order. Register via Task Scheduler (see
#          register-startup-task.ps1) so it runs automatically at every
#          startup without anyone double-clicking anything - this machine is
#          routinely fully powered off, not just asleep, so nothing here can
#          assume state survived from last time.
#
# Server currently running on the Mac Mini (192.168.1.12). Tracked under
# issue #1922 (multi-machine local k8s pool: MBP client + Mac Mini server +
# this Windows/WSL worker + Synology NAS storage).
#
# The join token is a cluster credential - never hardcode it here (this repo
# is public). Set it once via a persistent user env var before first run:
#   setx FAWKES_K3S_TOKEN "<token from: ssh mac-mini limactl shell k3s-worker -- sudo cat /var/lib/rancher/k3s/server/node-token>"
#
# Unattended runs (Task Scheduler, no one logged in) need passwordless sudo
# for the commands below, or they'll hang on a password prompt forever. Set
# this up once inside the WSL guest: `sudo visudo` and add a line scoped to
# just these commands (never blanket NOPASSWD:ALL):
#   <user> ALL=(ALL) NOPASSWD: /usr/bin/systemctl enable --now ssh, /usr/bin/systemctl start k3s-agent, /usr/local/bin/k3s-agent
# =============================================================================

#Requires -RunAsAdministrator

$K3sUrl = "https://192.168.1.12:6443"
$K3sToken = $env:FAWKES_K3S_TOKEN
$Distro = "Ubuntu"

if (-not $K3sToken) {
    Write-Error "FAWKES_K3S_TOKEN is not set. Run: setx FAWKES_K3S_TOKEN `"<token>`" then open a new shell."
    exit 1
}

Write-Host "== Network: mirrored mode =="
$wslConfigPath = "$env:UserProfile\.wslconfig"
$content = if (Test-Path $wslConfigPath) { Get-Content $wslConfigPath -Raw } else { "" }
if ($content -notmatch "networkingMode\s*=\s*mirrored") {
    Write-Host "Not set yet - applying and restarting WSL (first-time only; needs the shutdown below to take effect)."
    if ($content -match "\[wsl2\]") {
        $content = $content -replace "\[wsl2\]", "[wsl2]`nnetworkingMode=mirrored"
    } else {
        $content += "`n[wsl2]`nnetworkingMode=mirrored`n"
    }
    Set-Content -Path $wslConfigPath -Value $content
    wsl --shutdown
    Start-Sleep -Seconds 3
} else {
    Write-Host "Already set."
}

Write-Host "== Firewall rules =="
$rules = @(
    @{ Name = "WSL SSH"; Port = 22 }, @{ Name = "WSL k3s API"; Port = 6443 }, @{ Name = "WSL k3s Kubelet"; Port = 10250 }
)
foreach ($rule in $rules) {
    if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Action Allow -Protocol TCP -LocalPort $rule.Port | Out-Null
    }
}

Write-Host "== Starting WSL ($Distro) =="
wsl -d $Distro -- true

Write-Host "== SSH service =="
wsl -d $Distro -- bash -c "sudo systemctl enable --now ssh"

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
