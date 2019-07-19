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
choco upgrade all --noop > choco-versions.txt

Call :InstallIf adoptopenjdk , 8.192
Call :InstallIf awscli , 1.16.198
Call :InstallIf chefdk , 4.1.7
Call :InstallIf docker-cli , 18.09.6
Call :InstallIf docker-cli , 18.09.6
Call :InstallIf docker-compose , 1.24.0
Call :InstallIf docker-machine , 0.16.1
Call :InstallIf git , 2.22.0 
Call :InstallIf gitflow-avh , 0.0.0
Call :InstallIf googlechrome , 75.0.3770.142
Call :InstallIf helm , 2.14.2
Call :InstallIf inspec ,4.7.18
Call :InstallIf kubernetes-cli , 1.15.0
Call :InstallIf minikube , 1.2.0 
Call :InstallIf make , 4.2.1
Call :InstallIf maven , 3.6.1
:: nodejs lts is 10.16.0
Call :InstallIf nodejs , 10.16.0
Call :InstallIf postman , 7.2.2
Call :InstallIf selenium-chrome-driver , 75.0.3770.8
Call :InstallIf springtoolsuite , 3.9.6
Call :InstallIf terraform , 0.12.3
Call :InstallIf vagrant , 2.2.5
Call :InstallIf virtualbox , 6.0.10
Call :InstallIf vscode , 1.36.1

echo
echo space setup complete!
echo 


:: can we move this to a file and array?


for /f "tokens=1-2 delims=," %%i in (tool-suite.txt) do (
 echo name=%%i
 echo version=%%j
 Call :InstallIf %%i , %%j
)

:: refreshenv exits the script
refreshenv

:: Functions

:InstallIf
findstr /m "%~1 v%~2" choco-versions.txt
if %errorlevel%==0 (
echo Found %~1 %~2
) else (
echo installing %~1 %~2
choco install -y %~1 --version %~2
echo installed %~1 %~2
)
EXIT /B 0


