@ECHO OFF

echo Administrative permissions required. Detecting permissions...

net session >nul 2>&1
if %errorLevel% == 0 (
echo Success: Administrative permissions confirmed.
) else (
echo Failure: Current permissions inadequate.
pause >nul
exit
)

where /q choco
IF ERRORLEVEL 1 (
ECHO The choco is missing.
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
) ELSE (
ECHO choco exists. Let's go!
)

echo getting the versions of applications installed by choco...
:: choco upgrade all --noop > choco-versions.txt
choco list -local-only > choco-versions.txt

REM requires an external file
REM hard to coordinate and little value with other platforms
REM for /f "tokens=1-2 delims=," %%i in (tool-suite.txt) do (
REM  Call :InstallIf %%i , %%j
REM )
:: Call :InstallIf adoptopenjdk8 , 8.212.2
Call :InstallIf awscli , 2.4.6
Call :InstallIf aws-iam-authenticator ,  0.5.3
Call :InstallIf chef-workstation , 21.11.679
Call :InstallIf docker-cli , 19.03.12
Call :InstallIf docker-compose , 1.29.2
Call :InstallIf docker-machine , 0.16.2
Call :InstallIf git , 2.34.1
:: Call :InstallIf gitflow-avh , 0.0.0
Call :InstallIf golang , 1.17.5
Call :InstallIf googlechrome , 96.0.4664.110
:: Call :InstallIf inspec , 4.46.13 included in chef workstation
Call :InstallIf kubernetes-cli , 1.23.0
Call :InstallIf kubernetes-helm , 3.7.1
Call :InstallIf make , 4.3
Call :InstallIf maven , 3.8.4
Call :InstallIf minikube , 1.24.0 
Call :InstallIf microsoft-windows-terminal , 1.11.3471.0
:: nodejs lts is 16.13.0
Call :InstallIf nodejs , 16.13.0
:: LTS 8, 11, 17
Call :InstallIf openjdk17 , 17.0.1
Call :InstallIf postman , 9.4.1
Call :InstallIf python, 3.10.1
Call :InstallIf selenium-chrome-driver , 83.0.4103.39
Call :InstallIf serverless, 2.69.1
Call :InstallIf springtoolsuite , 3.9.6
Call :InstallIf terraform , 1.1.0
Call :InstallIf vagrant , 2.2.19
Call :InstallIf virtualbox , 6.1.30
Call :InstallIf vscode , 1.63.1

REM VS Code plugins from https://marketplace.visualstudio.com/VSCode
REM code --install-extension redhat.java
REM code --install-extension SonarSource.sonarlint-vscode
REM code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
REM code --install-extension ms-azuretools.vscode-docker
REM code --install-extention cameronsonatype.vscode-extension-nexus-iq

REM code --install-extention Pivotal.vscode-boot-dev-pack


echo
echo space setup complete!
echo 

:: refreshenv exits the script

refreshenv

GOTO:eof

EXIT /B n

:: Functions
:InstallIf
echo looking for "%~1 %~2"
findstr /I /C:"%~1 %~2" choco-versions.txt
if %errorlevel% EQU 0 (
  echo Found %~1 %~2
) else (
  echo installing %~1 %~2
  choco upgrade -y %~1 --version %~2
  echo installed %~1 %~2
)
EXIT /B 0


:End
REM 

EXIT /B n
