#!/bin/bash

set -euo pipefail

echo "Setting up your macOS development environment using Homebrew and Brewfile..."

# Function to check and install Homebrew
install_brew() {
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✅ Homebrew is already installed."
  fi
}

# Function to install dependencies from Brewfile
install_brew_bundle() {
  if [ ! -f Brewfile ]; then
    echo "Error: Brewfile not found in the current directory."
    exit 1
  fi

  echo "Installing dependencies from Brewfile..."
  brew bundle --file=Brewfile
}

# Function to test if a CLI tool is accessible
test_cli_tool() {
  local cmd="$1"
  if command -v "$cmd" &> /dev/null; then
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

# Install Homebrew if not already installed
install_brew

# Install dependencies from Brewfile
install_brew_bundle

# Test CLI tools
CLI_TOOLS=(
  git
  git-flow
  java
  docker
  docker-machine
  docker-compose
  aws
  node
  mvn
  vagrant
  VBoxManage
)

echo "Testing CLI tools accessibility..."
for tool in "${CLI_TOOLS[@]}"; do
  test_cli_tool "$tool"
done

# Test GUI apps
GUI_APPS=(
  "Visual Studio Code"
  "Google Chrome"
  "Slack"
  "Postman"
)

echo "Testing GUI apps installation..."
for app in "${GUI_APPS[@]}"; do
  test_gui_app "$app"
done

echo "All required tools and applications are installed and accessible."
