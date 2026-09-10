# =============================================================================
# File: scripts/homelab/register-startup-task.ps1
# Purpose: One-time setup - registers start-wsl-k3s-worker.ps1 as a Windows
#          Task Scheduler task that runs at every system startup (not just
#          user logon), as SYSTEM with highest privileges, so this machine
#          rejoins the k3s cluster automatically after being fully powered
#          off overnight - no one needs to be logged in or click anything.
#          Tracked under issue #1922.
#
# Run once, elevated: right-click PowerShell -> Run as Administrator, then
# execute this script.
# =============================================================================

#Requires -RunAsAdministrator

$TaskName = "FawkesK3sWorkerStartup"
$ScriptPath = Join-Path $PSScriptRoot "start-wsl-k3s-worker.ps1"

$Action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger `
    -Principal $Principal -Settings $Settings -Force | Out-Null

Write-Host "Registered scheduled task '$TaskName' to run $ScriptPath at every startup."
Write-Host "Note: it runs as SYSTEM, so FAWKES_K3S_TOKEN must be set as a SYSTEM/machine env var, not just your user one:"
Write-Host "  setx FAWKES_K3S_TOKEN `"<token>`" /M"
