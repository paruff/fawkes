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
Call :InstallIf adoptopenjdk8 , 8.212.2
Call :InstallIf awscli , 1.16.200
Call :InstallIf chefdk , 4.1.7
Call :InstallIf docker-cli , 18.09.6
Call :InstallIf docker-compose , 1.24.0
Call :InstallIf docker-machine , 0.16.1
Call :InstallIf git , 2.22.0 
Call :InstallIf gitflow-avh , 0.0.0
Call :InstallIf googlechrome , 75.0.3770.142
Call :InstallIf inspec ,4.7.18
Call :InstallIf kubernetes-cli , 1.15.1
Call :InstallIf kubernetes-helm , 2.14.2
Call :InstallIf make , 4.2.1
Call :InstallIf maven , 3.6.1
Call :InstallIf minikube , 1.2.0 
Call :InstallIf mobaxterm , 11.1.0
:: nodejs lts is 10.16.0
Call :InstallIf nodejs , 10.16.0
:: Call ?:InstallIf openjdk , 11.0.2.01
Call :InstallIf postman , 7.2.2
Call :InstallIf selenium-chrome-driver , 75.0.3770.8
Call :InstallIf springtoolsuite , 3.9.6
Call :InstallIf terraform , 0.12.5
Call :InstallIf vagrant , 2.2.5
Call :InstallIf virtualbox , 6.0.10
Call :InstallIf vscode , 1.36.1

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
GOTO End

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
REM refreshenv

EXIT /B n
