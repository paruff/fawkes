:: Chocolatey install script from earlier

if(test-path "C:\ProgramData\chocolatey\choco.exe"){

@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

}

:: Install all the packages
:: -y confirm yes for any prompt during the install process ﻿

choco install -y adoptopenjdk --version 8.192
choco install -y awscli --version 1.16.198
choco install -y git --version 2.22.0 # git 
choco install -y gitflow-avh --version 0.0.0 # branching methodology last updated 2015 ?
choco install -y docker-cli --version 18.09.6 # docker-toolbox ?
choco install -y docker-compose --version 1.24.0
choco install -y docker-machine --version 0.16.1
choco install -y helm --version 2.14.2
choco install -y kubernetes-cli --version 1.15.0
choco install -y minikube --version 1.2.0 
choco install -y maven --version 3.6.1
choco install -y nodejs-lts --version 10.16.0 # Node.js LTS, Recommended for most users
choco install -y postman --version 7.2.2
choco install -y springtoolsuite --version 3.9.6
choco install -y terraform --version 0.12.3
choco install -y vagrant --version 2.2.5
choco install -y virtualbox --version 6.0.10
choco install -y vscode --version 1.36.1

:: choco install <package_name> repeats for all the packages you want to install
﻿
:: foreach($PackageName in Get-Content .\tool-suite.txt) {
::     choco install $PackageName -y
:: }
