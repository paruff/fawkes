@echo off
REM =============================================================================
REM File: scripts/homelab/start-wsl-k3s-worker.bat
REM Purpose: Self-elevating wrapper for start-wsl-k3s-worker.ps1 - double-click
REM (or add to Windows startup) to join this machine's WSL guest to the
REM homelab k3s cluster as a worker node.
REM =============================================================================
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit -File \"%~dp0start-wsl-k3s-worker.ps1\"'"
