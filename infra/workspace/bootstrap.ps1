#Requires -RunAsAdministrator

Write-Host "Checking for administrative permissions..."

function Install-ChocolateyIfMissing {
    if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey not found. Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed."
    }
}

function Install-ChocolateyPackage {
    param (
        [Parameter(Mandatory)]
        [string]$PackageName,
        [string]$Version,
        [string]$PackageParameters,
        [switch]$Prerelease,
        [switch]$UseInstallNotUpgrade
    )
    $chocoExecutionArgs = "choco.exe"
    if ($UseInstallNotUpgrade) {
        $chocoExecutionArgs += " install"
    } else {
        $chocoExecutionArgs += " upgrade"
    }
    $chocoExecutionArgs += " $PackageName -y"
    if ($Prerelease) { $chocoExecutionArgs += " --prerelease" }
    if ($Version) { $chocoExecutionArgs += " --version='$Version'" }
    if ($PackageParameters) { $chocoExecutionArgs += " --package-parameters='$PackageParameters'" }

    Write-Host "Installing/upgrading $PackageName $Version ..."
    Invoke-Expression -Command $chocoExecutionArgs
    $exitCode = $LASTEXITCODE
    $validExitCodes = @(0, 1605, 1614, 1641, 3010)
    if ($validExitCodes -notcontains $exitCode) {
        Write-Error "Error installing $PackageName $Version. Exit code: $exitCode"
        exit 1
    }
}

Install-ChocolateyIfMissing

# Refresh Chocolatey package list
choco list -lo > $env:TEMP\choco-versions.txt

# List of packages to install (name, version)
$packages = @(
    @{ Name = "awscli"; Version = "2.4.6" },
    @{ Name = "aws-iam-authenticator"; Version = "0.5.3" },
    @{ Name = "azure-cli"; Version = "2.33.1" },
    @{ Name = "chef-workstation"; Version = "21.11.679" },
    @{ Name = "docker-cli"; Version = "19.03.12" },
    @{ Name = "docker-machine"; Version = "0.16.2" },
    @{ Name = "git"; Version = "2.34.1" },
    @{ Name = "gitversion.portable"; Version = "5.8.2" },
    @{ Name = "golang"; Version = "1.17.5" },
    @{ Name = "googlechrome"; Version = "96.0.4664.110" },
    @{ Name = "kubernetes-cli"; Version = "1.23.0" },
    @{ Name = "kubernetes-helm"; Version = "3.7.1" },
    @{ Name = "make"; Version = "4.3" },
    @{ Name = "maven"; Version = "3.8.4" },
    @{ Name = "minikube"; Version = "1.24.0" },
    @{ Name = "microsoft-windows-terminal"; Version = "1.11.3471.0" },
    @{ Name = "nodejs"; Version = "16.13.0" },
    @{ Name = "openjdk17"; Version = "17.0.1" },
    @{ Name = "postman"; Version = "9.4.1" },
    @{ Name = "selenium-chrome-driver"; Version = "83.0.4103.39" },
    @{ Name = "serverless"; Version = "2.69.1" },
    @{ Name = "springtoolsuite"; Version = "3.9.6" },
    @{ Name = "terraform"; Version = "1.1.0" },
    @{ Name = "vagrant"; Version = "2.2.19" },
    @{ Name = "virtualbox"; Version = "6.1.30" },
    @{ Name = "vscode"; Version = "1.63.1" }
)

foreach ($pkg in $packages) {
    Install-ChocolateyPackage -PackageName $pkg.Name -Version $pkg.Version
}

# Refresh environment for new tools
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv

Write-Host "`nSuccess! Your Windows development environment is ready.`n"