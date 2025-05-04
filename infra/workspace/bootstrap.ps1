#Requires -RunAsAdministrator

Write-Host "Checking for administrative permissions..."

function Install-DirectOrChoco {
    param (
        [Parameter(Mandatory)][string]$ToolName,
        [Parameter(Mandatory)][string]$CheckCommand,
        [Parameter(Mandatory)][string]$DirectUrl,
        [string]$ChocoName = $null,
        [string]$ChocoVersion = $null
    )
    if (Get-Command $CheckCommand -ErrorAction SilentlyContinue) {
        Write-Host "$ToolName is already installed."
        return
    }
    Write-Host "Installing $ToolName..."
    try {
        if ($DirectUrl) {
            $installer = "$env:TEMP\$ToolName-installer.exe"
            Invoke-WebRequest -Uri $DirectUrl -OutFile $installer
            Start-Process -FilePath $installer -ArgumentList "/quiet" -Wait
            Remove-Item $installer -Force
            if (Get-Command $CheckCommand -ErrorAction SilentlyContinue) {
                Write-Host "$ToolName installed successfully (direct)."
                return
            }
        }
    } catch {
        Write-Warning "Direct install failed for $ToolName. Trying Chocolatey..."
    }
    if ($ChocoName) {
        $chocoCmd = "choco install $ChocoName -y"
        if ($ChocoVersion) { $chocoCmd += " --version $ChocoVersion" }
        iex $chocoCmd
        if (Get-Command $CheckCommand -ErrorAction SilentlyContinue) {
            Write-Host "$ToolName installed successfully (choco)."
        } else {
            Write-Error "Failed to install $ToolName."
            exit 1
        }
    }
}

function Ensure-Chocolatey {
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey not found. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed."
    }
}

Ensure-Chocolatey

# Example: Install Git (direct from official, fallback to choco)
Install-DirectOrChoco -ToolName "Git" `
    -CheckCommand "git" `
    -DirectUrl "https://github.com/git-for-windows/git/releases/download/v2.34.1.windows.1/Git-2.34.1-64-bit.exe" `
    -ChocoName "git" `
    -ChocoVersion "2.34.1"

# Example: Install Node.js (direct from official, fallback to choco)
Install-DirectOrChoco -ToolName "Node.js" `
    -CheckCommand "node" `
    -DirectUrl "https://nodejs.org/dist/v16.13.0/node-v16.13.0-x64.msi" `
    -ChocoName "nodejs" `
    -ChocoVersion "16.13.0"

# Example: Install Docker Desktop (direct from official, fallback to choco)
Install-DirectOrChoco -ToolName "Docker Desktop" `
    -CheckCommand "docker" `
    -DirectUrl "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" `
    -ChocoName "docker-desktop"

# Add more tools as needed using the above pattern...

# Refresh environment for new tools
if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
    refreshenv
}

Write-Host "`nSuccess! Your Windows development environment is ready.`n"