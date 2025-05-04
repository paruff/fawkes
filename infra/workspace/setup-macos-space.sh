#!/bin/bash

set -euo pipefail

echo "Checking for administrative permissions (sudo may be required for some installs)..."

# Function to check and install Homebrew
install_brew() {
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew is already installed."
  fi
}

# Function to check and install a brew package
install_brew_package() {
  local pkg="$1"
  if ! brew list --formula | grep -qw "$pkg"; then
    echo "Installing $pkg..."
    brew install "$pkg"
  else
    echo "$pkg is already installed."
  fi
}

# Function to check and install a brew cask package
install_brew_cask() {
  local cask="$1"
  if ! brew list --cask | grep -qw "$cask"; then
    echo "Installing $cask..."
    brew install --cask "$cask"
  else
    echo "$cask is already installed."
  fi
}

# Function to test if a CLI tool is accessible
test_cli_tool() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    echo "✅ $cmd is accessible."
  else
    echo "❌ $cmd is NOT accessible."
    exit 1
  fi
}

# Function to test if a GUI app is installed (by checking /Applications)
test_gui_app() {
  local app="$1"
  if [ -d "/Applications/$app.app" ]; then
    echo "✅ $app is installed."
  else
    echo "❌ $app is NOT installed."
    exit 1
  fi
}

install_brew

# CLI tools
CLI_TOOLS=(
  git
  git-flow
  openjdk@8
  docker
  docker-machine
  docker-compose
  awscli
  node
  maven
  putty
  selenium-server
  vagrant
  virtualbox
)

for tool in "${CLI_TOOLS[@]}"; do
  install_brew_package "$tool"
done

# GUI apps
GUI_APPS=(
  visual-studio-code
  google-chrome
  slack
  postman
)

for app in "${GUI_APPS[@]}"; do
  install_brew_cask "$app"
done

echo "Testing CLI tools accessibility..."
test_cli_tool git
test_cli_tool git-flow
test_cli_tool java
test_cli_tool docker
test_cli_tool docker-machine
test_cli_tool docker-compose
test_cli_tool aws
test_cli_tool node
test_cli_tool mvn
test_cli_tool vagrant
test_cli_tool VBoxManage

# putty and selenium-server may not have direct CLI commands or may require PATH adjustment
if command -v putty &>/dev/null; then
  echo "✅ putty is accessible."
else
  echo "ℹ️ putty installed, but not found in PATH (may require manual launch)."
fi

if command -v selenium-server &>/dev/null; then
  echo "✅ selenium-server is accessible."
else
  echo "ℹ️ selenium-server installed, but not found in PATH (may require manual launch)."
fi

echo "Testing GUI apps installation..."
test_gui_app "Visual Studio Code"
test_gui_app "Google Chrome"
test_gui_app "Slack"
test_gui_app "Postman"

echo "All required tools are installed and accessible."
