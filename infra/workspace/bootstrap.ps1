#Requires -RunAsAdministrator

Write-Output "Administrative permissions required. Detecting permissions... Look above ...we will never get here if we are not running as admin"

function Install-ChocolateyPackage {
  param (
    [Parameter(Mandatory, Position=0)]
    [string]$PackageName,

    [string]$Source,

    [alias("Params")]
    [string]$PackageParameters,

    [string]$Version,

    [alias("Pre")]
    [switch]$Prerelease,

    [switch]$UseInstallNotUpgrade
  )

  $chocoExecutionArgs = "choco.exe"
  if ($UseInstallNotUpgrade) {
    $chocoExecutionArgs += " install"
  } else {
    $chocoExecutionArgs += " upgrade"
  }

  $chocoExecutionArgs += " $PackageName -y "
  if ($Prerelease) { $chocoExecutionArgs += " --prerelease"}
  if ($Version) { $chocoExecutionArgs += " --version='$Version'"}
  if ($PackageParameters -and $PackageParameters -ne '') { $chocoExecutionArgs += " --package-parameters='$PackageParameters'"}

  Invoke-Expression -Command $chocoExecutionArgs
  $exitCode = $LASTEXITCODE
  $validExitCodes = @(0, 1605, 1614, 1641, 3010)
  if ($validExitCodes -notcontains $exitCode) {
    throw "Error with package installation. See above."
  }
}


Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


Install-ChocolateyPackage awscli -Version 2.4.6
Install-ChocolateyPackage aws-iam-authenticator -Version  0.5.3
Install-ChocolateyPackage azure-cli -Version 2.33.1
Install-ChocolateyPackage chef-workstation -Version 21.11.679
Install-ChocolateyPackage docker-cli -Version 19.03.12
Install-ChocolateyPackage docker-machine -Version 0.16.2
Install-ChocolateyPackage git -Version 2.34.1
Install-ChocolateyPackage gitversion.portable -Version 5.8.2

Install-ChocolateyPackage golang -Version 1.17.5
# Install-ChocolateyPackage gcloudsdk -Version 0.0.0.20210904
Install-ChocolateyPackage googlechrome -Version 96.0.4664.110
Install-ChocolateyPackage kubernetes-cli -Version 1.23.0
Install-ChocolateyPackage kubernetes-helm -Version 3.7.1
Install-ChocolateyPackage make -Version 4.3
Install-ChocolateyPackage maven -Version 3.8.4
Install-ChocolateyPackage minikube -Version 1.24.0 
Install-ChocolateyPackage microsoft-windows-terminal -Version 1.11.3471.0
#  Install-ChocolateyPackage newman -Version 16.13.0
# nodejs lts is 16.13.0
Install-ChocolateyPackage nodejs -Version 16.13.0
# java LTS 8, 11, 17
Install-ChocolateyPackage openjdk17 -Version 17.0.1
Install-ChocolateyPackage postman -Version 9.4.1
# Install-ChocolateyPackage python -Version 3.10.1
Install-ChocolateyPackage selenium-chrome-driver -Version 83.0.4103.39
Install-ChocolateyPackage serverless -Version 2.69.1
Install-ChocolateyPackage springtoolsuite -Version 3.9.6
Install-ChocolateyPackage terraform -Version 1.1.0
Install-ChocolateyPackage vagrant -Version 2.2.19
Install-ChocolateyPackage virtualbox -Version 6.1.30
Install-ChocolateyPackage vscode -Version 1.63.1

# refreshenv
# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module.
# Note: Using `. $PROFILE` instead *may* work, but isn't guaranteed to.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# refreshenv is now an alias for Update-SessionEnvironment
# (rather than invoking refreshenv.cmd, the *batch file* for use with cmd.exe)
# This should make git.exe accessible via the refreshed $env:PATH, so that it
# can be called by name only.
refreshenv

# docker-machine create --driver virtualbox default
# minikube start

Write-Output "Success! Ready work in this space..."

# exit