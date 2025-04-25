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

install_brew

# CLI tools
install_brew_package git
install_brew_package git-flow
install_brew_package openjdk@8
install_brew_package docker
install_brew_package docker-machine
install_brew_package docker-compose
install_brew_package awscli
install_brew_package node
install_brew_package maven
install_brew_package putty
install_brew_package selenium-server
install_brew_package vagrant
install_brew_package virtualbox

# GUI apps
install_brew_cask visual-studio-code
install_brew_cask google-chrome
install_brew_cask slack
install_brew_cask postman

echo "All required tools are installed and up to date."
