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

for /f "tokens=1-2 delims=," %%i in (tool-suite.txt) do (
 Call :InstallIf %%i , %%j
)
echo
echo space setup complete!
echo 
:: refreshenv exits the script
refreshenv

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


