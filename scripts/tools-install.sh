#!/usr/bin/env bash
set -euo pipefail

# Minimal, careful installer helper to get Nix (recommended) and developer tooling
# onto a workstation. This script is interactive and will NOT run destructive
# commands without explicit user confirmation. It prints the commands it will
# run and asks to proceed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function confirm() {
  read -r -p "$1 [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

OS="$(uname -s)"
echo "Detected OS: ${OS}"

if [[ "$OS" == "Darwin" ]]; then
  echo "macOS detected. Recommended flow: install Homebrew, then install Nix, then use Nix devShell."

  if ! command -v brew > /dev/null 2>&1; then
    echo "Homebrew not found. Many dev tools install via Homebrew on macOS."
    if confirm "Install Homebrew now?"; then
      echo "Running Homebrew installer..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      echo "Homebrew installed (or attempted). You may need to follow any on-screen steps."
    else
      echo "Skipping Homebrew installation. You can install it later from https://brew.sh"
    fi
  else
    echo "Homebrew found: $(command -v brew)"
  fi

  echo
  echo "Next: Nix (provides reproducible dev shells)."
  echo "We'll run the official Nix installer script which may request sudo for multi-user installs."
  if confirm "Run Nix installer now? (see https://nixos.org/manual/nix/stable/#sect-installation)"; then
    echo "Installing Nix (this will run the official installer script)..."
    # shellcheck disable=SC2086
    curl -L https://nixos.org/nix/install | sh
    echo "Nix installer finished. You may need to restart your shell."
    echo "Recommend enabling experimental features for flakes and nix-command."
    if confirm "Add 'experimental-features = nix-command flakes' to your nix config now?"; then
      mkdir -p "$HOME/.config/nix"
      if [[ -f "$HOME/.config/nix/nix.conf" ]]; then
        echo "Appending experimental-features to $HOME/.config/nix/nix.conf"
        echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
      else
        cat > "$HOME/.config/nix/nix.conf" << EOF
experimental-features = nix-command flakes
EOF
      fi
      echo "Wrote $HOME/.config/nix/nix.conf"
    fi
  else
    echo "Skipping Nix installation. You can run the installer manually:"
    echo "  curl -L https://nixos.org/nix/install | sh"
  fi

  echo
  echo "Recommended: restart your terminal now or run 'source /etc/profile' or follow the installer's output."

elif [[ "$OS" == "Linux" ]]; then
  echo "Linux detected. We'll install Nix via the official installer script."
  echo "You may need sudo privileges depending on the distribution and installer mode."
  if confirm "Run Nix installer now?"; then
    curl -L https://nixos.org/nix/install | sh
    echo "Nix installer finished. Consider enabling flakes: add 'experimental-features = nix-command flakes' to /etc/nix/nix.conf or ~/.config/nix/nix.conf"
    if confirm "Add 'experimental-features = nix-command flakes' to your user nix config (~/.config/nix/nix.conf)?"; then
      mkdir -p "$HOME/.config/nix"
      cat > "$HOME/.config/nix/nix.conf" << EOF
experimental-features = nix-command flakes
EOF
      echo "Wrote $HOME/.config/nix/nix.conf"
    fi
  else
    echo "Skipping Nix installation. Run: curl -L https://nixos.org/nix/install | sh"
  fi

  echo
  echo "After Nix is available, run: nix --version and then 'nix develop infra/nix' from the repo root to get the dev shell."

else
  # Windows or unknown
  echo "Unsupported or special-case OS detected: $OS"
  echo "On Windows we strongly recommend using WSL2 (Windows Subsystem for Linux) and installing Nix inside the WSL distro."
  echo "Quick WSL setup steps (run in PowerShell as Administrator):"
  echo "  wsl --install -d ubuntu"
  echo "Then open the Ubuntu shell and run the Linux section of this script to install Nix inside WSL."
  echo
  echo "Alternatively, install required tools natively (kubectl/helm/terraform) via Chocolatey or winget, but Nix support on native Windows is experimental."
  if confirm "Show chocolatey/winget example commands?"; then
    cat << 'EOF'
choco install -y kubernetes-cli terraform kubectl-helm
# or using winget
winget install HashiCorp.Terraform
winget install Kubernetes.Kubectl
EOF
  fi
fi

echo
echo "When Nix is installed, you can enter the dev shell with:"
echo "  ./scripts/tools.sh shell"
echo "Or run the prerequisites check with:"
echo "  ./scripts/tools.sh check"

echo "Done."
