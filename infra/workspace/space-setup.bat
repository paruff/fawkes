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

where /q git
IF ERRORLEVEL 1 (
ECHO The git is missing.
choco install git -y
) ELSE (
ECHO git exists. Let's go!
)

where /q git
IF ERRORLEVEL 1 (
ECHO The git is missing.
choco install git-flow -y
) ELSE (
ECHO git exists. Let's go!
)

where /q code
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install visualstudiocode -y
) ELSE (
ECHO code exists. Let's go!
)

where /q javac
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install jdk8 -y
) ELSE (
ECHO javac exists. Let's go!
)

where /q docker
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install docker -y
) ELSE (
ECHO docker exists. Let's go!
)

where /q docker-machine
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install docker-machine -y
) ELSE (
ECHO docker-machine exists. Let's go!
)


where /q docker-compose
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install docker-compose -y
) ELSE (
ECHO docker-compose exists. Let's go!
)


where /q aws
IF ERRORLEVEL 1 (
ECHO The aws is missing.
choco install awscli -y
) ELSE (
ECHO awscli exists. Let's go!
)

where /q node
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install nodejs-lts  -y
) ELSE (
ECHO node exists. Let's go!
)

where /q slack
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install slack -y
) ELSE (
ECHO slack exists. Let's go!
)

where /q putty
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install putty -y
) ELSE (
ECHO putty exists. Let's go!
)

where /q chrome
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install googlechrome -y
) ELSE (
ECHO chrome exists. Let's go!
)

where /q selenium-chrome-driver
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install selenium-chrome-driver -y
) ELSE (
ECHO selenium-chrome-driver exists. Let's go!
)

where /q mvn
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install maven -y
) ELSE (
ECHO mvn exists. Let's go!
)

REM where /q sts
REM IF ERRORLEVEL 1 (
REM ECHO The application is missing.
REM choco install springtoolsuite -y
REM ) ELSE (
REM ECHO sts exists. Let's go!
REM )

where /q vagrant
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install vagrant -y
) ELSE (
ECHO vagrant exists. Let's go!
)

where /q virtualbox
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install virtualbox -y
) ELSE (
ECHO virtualbox exists. Let's go!
)

where /q postman
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install postman -y
) ELSE (
ECHO postman exists. Let's go!
)

where /q kubectl
IF ERRORLEVEL 1 (
ECHO The application is missing.
choco install minikube -y
) ELSE (
ECHO minikube exists. Let's go!
)

where /q terraform
IF ERRORLEVEL 1 (
ECHO The application is missing.
    choco install terraform -y
) ELSE (
    choco upgrade terraform -y
    ECHO terraform exists. Let's go!
)

where /q kubectl
IF ERRORLEVEL 1 (
ECHO The application is missing.
    choco install kubernetes-cli -y
) ELSE (
    choco upgrade kubernetes-cli -y
    ECHO kubectl exists. Let's go!
)

where /q helm
IF ERRORLEVEL 1 (
ECHO The application is missing.
    choco install kubernetes-helm -y
) ELSE (
    choco upgrade kubernetes-helm -y
    ECHO helm exists. Let's go!
)

where /q kubectl
IF ERRORLEVEL 1 (
ECHO The application is missing.
    choco install kubernetes-cli -y
) ELSE (
    choco upgrade kubernetes-cli -y
    ECHO kubectl exists. Let's go!
)

refreshenv
docker-machine create --driver virtualbox default
minikube start

echo Success! Ready work in this space...
pause >nul
exit