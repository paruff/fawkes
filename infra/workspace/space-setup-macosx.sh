#!/bin/sh

# Install Homebrew
which brew > /dev/null 2>&1
if [ $? -eq 1 ]; then
	#Cheat, if we don't have brew, install xcode command line utils too
	xcode-select --install

	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	brew update
fi

# Homebrew packages to install
BREW_PKGS=(
	aws-shell
    git
    git-flow
    maven
    docker
    docker-compose
    docker-machine
    kubernetes-cli
    node
)
for i in "${BREW_PKGS[@]}"
do
	brew install $i
done

# Install oh-my-zsh & nvm configs
if [ -n "$ZSH_VERSION" ]; then
	chsh -s /bin/zsh
	sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
	echo "export LC_ALL=en_US.UTF-8\nexport LANG=en_US.UTF-8" >> ~/.zshrc

	mkdir ~/.nvm
	echo "export NVM_DIR=\"$HOME\"/.nvm\n. /usr/local/opt/nvm/nvm.sh" > ~/.zshrc
	source ~/.zshrc
	nvm install stable
	npm install -global eslint
fi

# Brew Cask packages to install
brew tap caskroom/cask

BREW_CASKS=(
	adoptopenjdk8
	google-chrome
	iterm2
    minikube
	postman
    slack
    springtoolsuite
    vagrant
    virtualbox
    virtualbox-extension-pack
	visual-studio-code
    terraform
)

for i in "${BREW_CASKS[@]}"
do
	brew cask install $i
done

# Install from mac app store

echo "Installing Mac App Store apps..."
MAS_APPS=(
	803453959 # Slack
)
for i in "${MAS_APPS[@]}"
do
	mas install $i
done

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
defaults write NSGlobalDomain KeyRepeat -int 1

# Dark interface is best interface
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Autohide the dock
defaults write com.apple.dock autohide -int 1

# Remove everything from taskbar, alfred is better
# for getting to and opening apps anyways

defaults read com.apple.dock persistent-apps | grep file-label > /dev/null 2>&1
while [ $? -eq 0 ]; do
	/usr/libexec/PlistBuddy -c "Delete persistent-apps:0" ~/Library/Preferences/com.apple.dock.plist
done
