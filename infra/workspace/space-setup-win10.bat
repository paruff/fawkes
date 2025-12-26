@ECHO OFF

:: Windows 10 developer environment setup using Chocolatey

echo Checking for administrative permissions...
net session >nul 2>&1
if %errorLevel% == 0 (
  echo Success: Administrative permissions confirmed.
) else (
  echo Failure: Current permissions inadequate.
  pause >nul
  exit /b 1
)

:: Ensure Chocolatey is installed
where /q choco
IF ERRORLEVEL 1 (
  ECHO Chocolatey not found. Installing...
  @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
  SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
) ELSE (
  ECHO Chocolatey is already installed.
)

:: List installed Chocolatey packages
choco list -local-only > choco-versions.txt

:: Install required tools (name, version)
Call :InstallIf awscli 2.4.6
Call :InstallIf aws-iam-authenticator 0.5.3
Call :InstallIf chef-workstation 21.11.679
Call :InstallIf docker-cli 19.03.12
Call :InstallIf docker-compose 1.29.2
Call :InstallIf docker-machine 0.16.2
Call :InstallIf git 2.34.1
Call :InstallIf golang 1.17.5
Call :InstallIf googlechrome 96.0.4664.110
Call :InstallIf kubernetes-cli 1.23.0
Call :InstallIf kubernetes-helm 3.7.1
Call :InstallIf make 4.3
Call :InstallIf maven 3.8.4
Call :InstallIf minikube 1.24.0
Call :InstallIf microsoft-windows-terminal 1.11.3471.0
:: Call :InstallIf newman 16.13.0
Call :InstallIf nodejs 16.13.0
Call :InstallIf openjdk17 17.0.1
Call :InstallIf postman 9.4.1
Call :InstallIf python 3.10.1
Call :InstallIf selenium-chrome-driver 83.0.4103.39
Call :InstallIf serverless 2.69.1
Call :InstallIf springtoolsuite 3.9.6
Call :InstallIf terraform 1.1.0
Call :InstallIf vagrant 2.2.19
Call :InstallIf virtualbox 6.1.30
Call :InstallIf vscode 1.63.1

:: VS Code extensions (uncomment if you want to auto-install)
REM code --install-extension redhat.java
REM code --install-extension SonarSource.sonarlint-vscode
REM code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
REM code --install-extension ms-azuretools.vscode-docker
REM code --install-extension cameronsonatype.vscode-extension-nexus-iq
REM code --install-extension Pivotal.vscode-boot-dev-pack

echo.
echo Space setup complete!
echo.

EXIT /B 0

:: Function to install a tool if not already present at the specified version
:InstallIf
setlocal
set "PKG=%~1"
set "VER=%~2"
findstr /I /C:"%PKG% %VER%" choco-versions.txt >nul
if %errorlevel% EQU 0 (
  echo Found %PKG% %VER%
) else (
  echo Installing %PKG% %VER%...
  choco upgrade -y %PKG% --version %VER%
  if %errorlevel% NEQ 0 (
    echo ERROR: Failed to install %PKG% %VER%
    exit /b 1
  )
  echo Installed %PKG% %VER%
)
endlocal
EXIT /B 0
