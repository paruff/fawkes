#!/bin/bash
# Mac os workspace setup/bootstrap file using brew.sh to install packages for mac os 


function brew_install_if0 () 
{
  echo " brew: package: $1, version: $2"
  if grep -Fxq "$1 $2" brew-versions.txt 
  then
	echo "$1@$2 installed"
  else
    echo "installing $1  - @$2"
	brew install $1 
  #@$2

  # brew extract --version='version_no' <package_name> <tap_name>
  # Example: brew extract --version='1.9' haproxy homebrew/core
    fi
}


function cask_install_if0 () 
{
  echo " brew: package: $1, version: $2"
  if grep -Fxq "$1 $2" brew-versions.txt 
  then
	echo "$1@$2 installed"
  else
    echo "installing $1  - @$2"
	brew cask upgrade $1 #@$2
  fi
}

# Install Homebrew
which brew > /dev/null 2>&1
if [ $? -eq 1 ]; then
	#Cheat, if we don't have brew, install xcode command line utils too
	xcode-select --install

	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	brew update
fi
#
brew list --versions > brew-versions.txt
# brew cask list --versions >> brew-versions.txt

brew_install_if0 awscli 2.4.6
brew_install_if0 aws-iam-authenticator 0.5.3
brew_install_if0 azure-cli 2.0
brew_install_if0 chef-workstation 21.11.679
brew_install_if0 chromedriver 96.0.4664.45
brew_install_if0 docker 20.10.12
brew_install_if0 docker-compose 2.2.2
brew_install_if0 docker-machine 0.16.2
brew_install_if0 git 2.23.1
brew_install_if0 go 1.17
brew_install_if0 google-chrome 96.0.4664.110
brew_install_if0 iterm2  3.4.15
brew_install_if0 openjdk 17.0.1
brew_install_if0 maven 3.8.4
brew_install_if0 kubernetes-cli 1.15.1
brew_install_if0 newman 5.3.0
brew_install_if0 node@17 17.2.0
brew_install_if0 postman 9.5.0
brew_install_if0 serverless 2.69.1
brew_install_if0 springtoolsuite 4.22.0
brew_install_if0 terraform 1.1.1
brew_install_if0 vagrant 2.2.19
brew_install_if0 virtualbox 6.1.0
brew_install_if0 virtualbox-extension-pack
brew_install_if0 visual-studio-code 1.63.2


# Install from mac app store

# echo "Installing Mac App Store apps..."
# MAS_APPS=(
# 	803453959 # Slack
# )
# for i in "${MAS_APPS[@]}"
# do
# 	mas install $i
# done

########################################################
#               System Default Settings
#
# Instead of using the UI, we can just set things here
# so each new system we setup just has our settings.
# Much better than being surprised and trying to 
# remember what setting to change.
########################################################

# Default cursor speed is slow when holding keys
# 0 is TOO FAST, 1 is good. (2 is min available in UI)
# defaults write NSGlobalDomain KeyRepeat -int 1

# Dark interface is best interface
# defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Autohide the dock
# defaults write com.apple.dock autohide -int 1

# Remove everything from taskbar, alfred is better
# for getting to and opening apps anyways

# defaults read com.apple.dock persistent-apps | grep file-label > /dev/null 2>&1
# while [ $? -eq 0 ]; do
# 	/usr/libexec/PlistBuddy -c "Delete persistent-apps:0" ~/Library/Preferences/com.apple.dock.plist
# done
