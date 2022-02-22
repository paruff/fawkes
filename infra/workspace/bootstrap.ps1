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

  $chocoExecutionArgs += " $PackageName -y --source='$Source'"
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

Install-ChocolateyPackage gcloudsdk -Source https://internal/repo/v2 -Version 0.0.0.20210904
Install-ChocolateyPackage ojdkbuild -Source https://internal/repo/v2 -Version 17.0.1.0
Install-ChocolateyPackage vscode -Source https://internal/repo/v2 -Version 1.64.2
Install-ChocolateyPackage docker-desktop -Source https://internal/repo/v2 -Version 4.5.0
Install-ChocolateyPackage docker-machine -Source https://internal/repo/v2 -Version 0.16.2
