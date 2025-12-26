#Requires -RunAsAdministrator

Write-Host "Checking for administrative permissions..."

# Ensure PowerShellGet is available for native package management
function Ensure-PowerShellGet {
    if (-not (Get-Command Install-Package -ErrorAction SilentlyContinue)) {
        Write-Host "PowerShellGet not found. Installing PowerShellGet..."
        Install-Module -Name PowerShellGet -Force -SkipPublisherCheck
    } else {
        Write-Host "✅ PowerShellGet is already installed."
    }
}

# Ensure Chocolatey is installed (fallback)
function Ensure-Chocolatey {
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey not found. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "✅ Chocolatey is already installed."
    }
}

# Install a tool using PowerShell native methods or fallback to Chocolatey
function Ensure-Tool {
    param (
        [Parameter(Mandatory)][string]$ToolName,
        [Parameter(Mandatory)][string]$NativeName,  # Name for winget or Install-Package
        [Parameter(Mandatory)][string]$ChocoName,  # Name for Chocolatey
        [Parameter(Mandatory)][string]$Version
    )

    # Try PowerShell native installation first
    $installed = Get-Package -Name $NativeName -ErrorAction SilentlyContinue
    if ($installed -and $installed.Version -eq $Version) {
        Write-Host "✅ $ToolName ($Version) is already installed via PowerShell."
    } else {
        Write-Host "Installing $ToolName ($Version) via PowerShell..."
        try {
            Install-Package -Name $NativeName -RequiredVersion $Version -Force -Scope CurrentUser -ErrorAction Stop
            Write-Host "✅ $ToolName ($Version) installed successfully via PowerShell."
        } catch {
            Write-Host "⚠️ PowerShell native installation failed for $ToolName. Falling back to Chocolatey..."
            choco install $ChocoName --version=$Version -y --no-progress
            if ($?) {
                Write-Host "✅ $ToolName ($Version) installed successfully via Chocolatey."
            } else {
                Write-Error "❌ Failed to install $ToolName ($Version)."
                exit 1
            }
        }
    }
}

# Ensure PowerShellGet and Chocolatey are installed
Ensure-PowerShellGet
Ensure-Chocolatey

# Define the desired state for tools
$tools = @(
    @{ ToolName = "AWS CLI"; NativeName = "AWS.Tools.Common"; ChocoName = "awscli"; Version = "2.4.6" },
    @{ ToolName = "AWS IAM Authenticator"; NativeName = ""; ChocoName = "aws-iam-authenticator"; Version = "0.5.3" },
    @{ ToolName = "Chef Workstation"; NativeName = ""; ChocoName = "chef-workstation"; Version = "21.11.679" },
    @{ ToolName = "Docker CLI"; NativeName = ""; ChocoName = "docker-cli"; Version = "19.03.12" },
    @{ ToolName = "Docker Compose"; NativeName = ""; ChocoName = "docker-compose"; Version = "1.29.2" },
    @{ ToolName = "Docker Machine"; NativeName = ""; ChocoName = "docker-machine"; Version = "0.16.2" },
    @{ ToolName = "Git"; NativeName = "Git.Git"; ChocoName = "git"; Version = "2.34.1" },
    @{ ToolName = "GoLang"; NativeName = ""; ChocoName = "golang"; Version = "1.17.5" },
    @{ ToolName = "Google Chrome"; NativeName = ""; ChocoName = "googlechrome"; Version = "96.0.4664.110" },
    @{ ToolName = "Kubernetes CLI"; NativeName = ""; ChocoName = "kubernetes-cli"; Version = "1.23.0" },
    @{ ToolName = "Kubernetes Helm"; NativeName = ""; ChocoName = "kubernetes-helm"; Version = "3.7.1" },
    @{ ToolName = "Make"; NativeName = ""; ChocoName = "make"; Version = "4.3" },
    @{ ToolName = "Maven"; NativeName = ""; ChocoName = "maven"; Version = "3.8.4" },
    @{ ToolName = "Minikube"; NativeName = ""; ChocoName = "minikube"; Version = "1.24.0" },
    @{ ToolName = "Windows Terminal"; NativeName = "Microsoft.WindowsTerminal"; ChocoName = "microsoft-windows-terminal"; Version = "1.11.3471.0" },
    @{ ToolName = "Node.js"; NativeName = "NodeJS"; ChocoName = "nodejs"; Version = "16.13.0" },
    @{ ToolName = "OpenJDK 17"; NativeName = ""; ChocoName = "openjdk17"; Version = "17.0.1" },
    @{ ToolName = "Postman"; NativeName = ""; ChocoName = "postman"; Version = "9.4.1" },
    @{ ToolName = "Python"; NativeName = "Python"; ChocoName = "python"; Version = "3.10.1" },
    @{ ToolName = "Selenium Chrome Driver"; NativeName = ""; ChocoName = "selenium-chrome-driver"; Version = "83.0.4103.39" },
    @{ ToolName = "Serverless Framework"; NativeName = ""; ChocoName = "serverless"; Version = "2.69.1" },
    @{ ToolName = "Spring Tool Suite"; NativeName = ""; ChocoName = "springtoolsuite"; Version = "3.9.6" },
    @{ ToolName = "Terraform"; NativeName = ""; ChocoName = "terraform"; Version = "1.1.0" },
    @{ ToolName = "Vagrant"; NativeName = ""; ChocoName = "vagrant"; Version = "2.2.19" },
    @{ ToolName = "VirtualBox"; NativeName = ""; ChocoName = "virtualbox"; Version = "6.1.30" },
    @{ ToolName = "Visual Studio Code"; NativeName = "Microsoft.VisualStudioCode"; ChocoName = "vscode"; Version = "1.63.1" }
)

# Ensure each tool is installed
foreach ($tool in $tools) {
    Ensure-Tool -ToolName $tool.ToolName -NativeName $tool.NativeName -ChocoName $tool.ChocoName -Version $tool.Version
}

Write-Host "`n✅ Success! Your Windows development environment is ready.`n"
