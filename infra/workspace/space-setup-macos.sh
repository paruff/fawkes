#!/bin/bash

echo Administrative permissions required. Detecting permissions...

net session >nul 2>&1
if %errorLevel% == 0 (
echo Success: Administrative permissions confirmed.
) else (
echo Failure: Current permissions inadequate.
pause >nul

)

whereis brew
IF ERRORLEVEL 1 (
ECHO The brew is missing.
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
) ELSE (
ECHO brew exists. Lets go!
)

whereis git
IF ERRORLEVEL 1 (
ECHO The git is missing.
brew install git -y
) ELSE (
ECHO git exists. Lets go!
)

whereis git
IF ERRORLEVEL 1 (
ECHO The git is missing.
brew install git-flow -y
) ELSE (
ECHO git exists. Lets go!
)

whereis code
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew cask install visual-studio-code
# brewinstall visualstudiocode -y
) ELSE (
ECHO code exists. Lets go!
)

whereis javac
IF ERRORLEVEL 1 (
ECHO The application is missing.
brewinstall jdk8 -y
) ELSE (
ECHO javac exists. Lets go!
)

whereis docker
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install docker -y
) ELSE (
ECHO docker exists. Lets go!
)

whereis docker-machine
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install docker-machine -y
) ELSE (
ECHO docker-machine exists. Lets go!
)


whereis docker-compose
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install docker-compose -y
) ELSE (
ECHO docker-compose exists. Lets go!
)


whereis aws
IF ERRORLEVEL 1 (
ECHO The aws is missing.
brew install awscli -y
) ELSE (
ECHO awscli exists. Lets go!
)

whereis node
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install nodejs-lts  -y
) ELSE (
ECHO node exists. Lets go!
)

whereis slack
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install slack -y
) ELSE (
ECHO slack exists. Lets go!
)

whereis putty
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install putty -y
) ELSE (
ECHO putty exists. Lets go!
)

whereis chrome
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install googlechrome -y
) ELSE (
ECHO chrome exists. Lets go!
)

whereis selenium-chrome-driver
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install selenium-chrome-driver -y
) ELSE (
ECHO selenium-chrome-driver exists. Lets go!
)

whereis mvn
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install maven -y
) ELSE (
ECHO mvn exists. Lets go!
)

REM whereis sts
REM IF ERRORLEVEL 1 (
REM ECHO The application is missing.
REM brew install springtoolsuite -y
REM ) ELSE (
REM ECHO sts exists. Lets go!
REM )

whereis vagrant
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install vagrant -y
) ELSE (
ECHO vagrant exists. Lets go!
)

whereis virtualbox
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install virtualbox -y
) ELSE (
ECHO virtualbox exists. Lets go!
)

whereis postman
IF ERRORLEVEL 1 (
ECHO The application is missing.
brew install postman -y
) ELSE (
ECHO postman exists. Lets go!
)

refreshenv
