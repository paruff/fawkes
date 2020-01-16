#Requires -RunAsAdministrator

$ChocoInstalled = $false
if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    $ChocoInstalled = $true
}
else {
    Write-Host "chocolatey does not exist"
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

choco list -local-only > choco-versions.txt


InstallIf adoptopenjdk8 , 8.212.2
#InstallIf awscli , 1.16.200
#InstallIf chefdk , 4.1.7
#InstallIf docker-cli , 18.09.6
#InstallIf docker-compose , 1.24.0
#InstallIf docker-machine , 0.16.1
#InstallIf git , 2.22.0 
#InstallIf gitflow-avh , 0.0.0
#InstallIf googlechrome , 75.0.3770.142
#InstallIf inspec ,4.7.18
#InstallIf kubernetes-cli , 1.15.1
#InstallIf kubernetes-helm , 2.14.2
#InstallIf make , 4.2.1
#InstallIf maven , 3.6.1
#InstallIf minikube , 1.2.0 
#InstallIf mobaxterm , 11.1.0
## nodejs lts is 10.16.0
#InstallIf nodejs , 10.16.0
## Call ?:InstallIf openjdk , 11.0.2.01
#InstallIf postman , 7.2.2
#InstallIf selenium-chrome-driver , 75.0.3770.8
#InstallIf springtoolsuite , 3.9.6
#InstallIf terraform , 0.12.5
#InstallIf vagrant , 2.2.5
#InstallIf virtualbox , 6.0.10
#InstallIf vscode , 1.36.1


function InstallIf {

Param ([String]$package,[String]$version)

if (Select-String -Path choco-versions.txt -Pattern "$package" -Quiet)
{
    Write-Output Found $package $version
}
else
{
Write-Output installing $package $version
choco upgrade "$package"  -y --version "$version"
Write-Output intalled $package $version
}
}