# =============================================================================
# File: scripts/homelab/prepare-wsl-connections.ps1
# Purpose: Make a WSL2 guest (Ubuntu) reachable from other machines on the
#          LAN - SSH (22) and k3s (6443 API, 10250 kubelet). Tracked under
#          issue #1922 (multi-machine local k8s pool: MBP + Mac Mini + this
#          Windows/WSL box + Synology NAS for storage).
#
# WSL2 uses NAT by default: services inside the guest are NOT reachable via
# the Windows host's LAN IP even if they're listening. This enables WSL's
# mirrored networking mode (the guest shares the host's network directly -
# no per-reboot IP juggling) and opens the matching firewall rules.
#
# Run as Administrator (Start-Process powershell -Verb RunAs -ArgumentList
# "-File `"$PWD\prepare-wsl-connections.ps1`"" from a non-elevated shell).
# =============================================================================

#Requires -RunAsAdministrator

$wslConfigPath = "$env:UserProfile\.wslconfig"

Write-Host "== .wslconfig (mirrored networking) =="
if (Test-Path $wslConfigPath) {
    $content = Get-Content $wslConfigPath -Raw
} else {
    $content = ""
}

if ($content -match "networkingMode\s*=\s*mirrored") {
    Write-Host ".wslconfig already has networkingMode=mirrored."
} else {
    if ($content -match "\[wsl2\]") {
        $content = $content -replace "\[wsl2\]", "[wsl2]`nnetworkingMode=mirrored"
    } else {
        $content += "`n[wsl2]`nnetworkingMode=mirrored`n"
    }
    Set-Content -Path $wslConfigPath -Value $content
    Write-Host "Added networkingMode=mirrored to $wslConfigPath"
}

Write-Host "== Firewall rules =="
$rules = @(
    @{ Name = "WSL SSH";          Port = 22 },
    @{ Name = "WSL k3s API";      Port = 6443 },
    @{ Name = "WSL k3s Kubelet";  Port = 10250 }
)
foreach ($rule in $rules) {
    if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Action Allow `
            -Protocol TCP -LocalPort $rule.Port | Out-Null
        Write-Host "Created firewall rule: $($rule.Name) (TCP $($rule.Port))"
    } else {
        Write-Host "Firewall rule already exists: $($rule.Name)"
    }
}

Write-Host "== Restarting WSL to apply mirrored networking =="
wsl --shutdown
Start-Sleep -Seconds 3
wsl -d Ubuntu -- true
Write-Host "WSL restarted. It should now be reachable at this machine's LAN IP."
Write-Host "Verify from another machine: ssh <user>@<this-windows-host-ip>"
