#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BREWFILE_PATH="${REPO_ROOT}/Brewfile"

NON_INTERACTIVE=0
ACCEPT_DRIVER_PERMS=0
DEPRECATED_NO_LOCK=0

usage() {
  cat << EOF
Usage: $0 [options]

Options:
  -y, --yes                         Run non-interactively (auto-accept prompts)
      --accept-driver-permissions   Automatically set hyperkit driver permissions (sudo)
  -f, --file <path>                 Path to Brewfile (default:
                                    ${BREWFILE_PATH})
      --no-lock                     Deprecated: ignored (brew bundle removed this flag)
  -h, --help                        Show this help
EOF
}

# Parse arguments
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y | --yes)
      NON_INTERACTIVE=1
      shift
      ;;
    --accept-driver-permissions)
      ACCEPT_DRIVER_PERMS=1
      shift
      ;;
    -f | --file)
      BREWFILE_PATH="${2:-}"
      shift 2
      ;;
    --no-lock)
      DEPRECATED_NO_LOCK=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      # Ignore unknown args to be friendly with wrappers
      ARGS+=("$1")
      shift
      ;;
  esac
done

confirm() {
  if [[ ${NON_INTERACTIVE} -eq 1 ]]; then return 0; fi
  local prompt="$1"
  read -r -p "${prompt} [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "brew-install.sh is intended for macOS only." >&2
  exit 2
fi

if ! command -v brew > /dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Try to make brew available in this shell
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  if ! command -v brew > /dev/null 2>&1; then
    echo "Brew installed but not on PATH yet. Follow the installer output to add it, then re-run this script." >&2
    exit 1
  fi
fi

if [[ ! -f "${BREWFILE_PATH}" ]]; then
  echo "Brewfile not found at ${BREWFILE_PATH}" >&2
  exit 1
fi

echo "Using Brewfile: ${BREWFILE_PATH}"
if [[ ${NON_INTERACTIVE} -eq 0 ]]; then
  echo "Preview of Brewfile contents:" && echo "--------------------------------" && cat "${BREWFILE_PATH}" && echo
  if ! confirm "Proceed to install the above packages via Homebrew?"; then
    echo "Aborted by user."
    exit 1
  fi
fi

echo "Running Homebrew bundle..."
bundle_args=(--file="${BREWFILE_PATH}")
# Note: --no-lock was removed from brew bundle. If provided, we ignore it.
if [[ ${DEPRECATED_NO_LOCK} -eq 1 ]]; then
  echo "Note: --no-lock is deprecated and ignored (no longer supported by brew bundle)."
fi
brew bundle "${bundle_args[@]}"

echo "Post-install: hyperkit driver check (only relevant on Intel macs with hyperkit installed)"
if command -v docker-machine-driver-hyperkit > /dev/null 2>&1; then
  DRIVER_PATH="$(command -v docker-machine-driver-hyperkit)"
  echo "Found hyperkit driver at ${DRIVER_PATH}."
  if [[ ${NON_INTERACTIVE} -eq 1 || ${ACCEPT_DRIVER_PERMS} -eq 1 ]]; then
    echo "Setting setuid on hyperkit driver (requires sudo)..."
    sudo chown root:wheel "${DRIVER_PATH}"
    sudo chmod u+s "${DRIVER_PATH}"
    echo "Driver permissions updated."
  else
    if confirm "Run sudo chown root:wheel ${DRIVER_PATH} && sudo chmod u+s ${DRIVER_PATH}?"; then
      sudo chown root:wheel "${DRIVER_PATH}"
      sudo chmod u+s "${DRIVER_PATH}"
      echo "Driver permissions updated."
    else
      echo "Skipped driver permission changes. You may need to do this for hyperkit usage."
    fi
  fi
fi

echo "Docker Desktop may require manual steps (first-run login, permissions). If installed, open it now."

# Recommend a driver based on architecture and installed tools
ARCH="$(uname -m)"
if [[ "${ARCH}" == "arm64" ]]; then
  echo "Done. Recommended for Apple Silicon (arm64):"
  echo "  minikube start --driver=docker --memory=8192 --cpus=4"
else
  if command -v docker-machine-driver-hyperkit > /dev/null 2>&1; then
    echo "Done. Recommended on Intel with hyperkit:"
    echo "  minikube start --driver=hyperkit --memory=8192 --cpus=4"
  else
    echo "Done. Recommended fallback:"
    echo "  minikube start --driver=docker --memory=8192 --cpus=4"
  fi
fi
