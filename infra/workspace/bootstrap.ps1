install-module cChoco

Set-WSManInstance -ValueSet @{MaxEnvelopeSizekb "10000"} -ResourceURI winrm/config

Start-DscConfiguration .\fawkesChocoConfig -wait -Verbose -force 


# function Install-ChocolateyPackage {
#     param (
#       [Parameter(Mandatory, Position=0)]
#       [string]$PackageName,
  
#       [string]$Source,
  
#       [alias("Params")]
#       [string]$PackageParameters,
  
#       [string]$Version,
  
#       [alias("Pre")]
#       [switch]$Prerelease,
  
#       [switch]$UseInstallNotUpgrade
#     )
  
#     $chocoExecutionArgs = "choco.exe"
#     if ($UseInstallNotUpgrade) {
#       $chocoExecutionArgs += " install"
#     } else {
#       $chocoExecutionArgs += " upgrade"
#     }
  
#     $chocoExecutionArgs += " $PackageName -y"
#     if ($Prerelease) { $chocoExecutionArgs += " --prerelease"}
#     if ($Version) { $chocoExecutionArgs += " --version='$Version'"}
#     if ($PackageParameters -and $PackageParameters -ne '') { $chocoExecutionArgs += " --package-parameters='$PackageParameters'"}
  
#     Invoke-Expression -Command $chocoExecutionArgs
#     $exitCode = $LASTEXITCODE
#     $validExitCodes = @(0, 1605, 1614, 1641, 3010)
#     if ($validExitCodes -notcontains $exitCode) {
#       throw "Error with package installation. See above."
#     }
#   }
  
#   Install-ChocolateyPackage gcloudsdk  -Version 0.0.0.20210904
#   Install-ChocolateyPackage ojdkbuild   -Version 17.0.1.0
#   Install-ChocolateyPackage vscode   -Version 1.64.2
#   Install-ChocolateyPackage docker-desktop   -Version 4.5.0
#   Install-ChocolateyPackage docker-machine   -Version 0.16.2
  