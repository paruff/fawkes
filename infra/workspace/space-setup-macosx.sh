#!/bin/bash


function brew_install_if0 () 
{
  echo " brew: package: $1, version: $2"
  if grep -Fxq "$1 $2" brew-versions.txt 
  then
	echo "$1@$2 installed"
  else
    echo "installing $1  - @$2"
	brew upgrade $1 #@$2
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
brew cask list --versions >> brew-versions.txt

brew_install_if0 awscli 1.16.200
brew_install_if0 git 2.22.0_1
brew_install_if0 git-flow 0.4.1
brew_install_if0 maven 3.6.0
brew_install_if0 docker 19.03.0_1
brew_install_if0 docker-compose 1.24.1
brew_install_if0 docker-machine 0.16.1
brew_install_if0 kubernetes-cli 1.15.1
brew_install_if0 node@10 10.16.0
brew_install_if0 terraform 0.12.4

# Brew Cask packages to install
brew tap caskroom/cask

cask_install_if0 adoptopenjdk8
cask_install_if0 google-chrome
cask_install_if0 iterm2 
cask_install_if0 minikube 1.2.0
cask_install_if0 postman 7.3.4
cask_install_if0 slack
cask_install_if0 springtoolsuite 4.3.1
cask_install_if0 vagrant 2.2.5
# cask_install_if0 virtualbox 6.0.10
# cask_install_if0 virtualbox-extension-pack
cask_install_if0 visual-studio-code 1.36.1
# cask_install_if0 

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
