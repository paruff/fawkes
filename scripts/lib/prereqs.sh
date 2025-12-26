#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/prereqs.sh

set -euo pipefail
# Purpose: Prerequisite checking and tool installation
# =============================================================================


set -euo pipefail
check_prereqs() {
  echo "🔎 Validating prerequisites..."
  local script_dir="$(dirname "${BASH_SOURCE[0]}")/.."
  if [[ -f "${script_dir}/tools.sh" ]]; then
    echo "➡ Running tools check via scripts/tools.sh"
    if ! "${script_dir}/tools.sh" check; then
      echo "Some required tools are missing in your environment."
      echo "You can enter the Nix dev shell to get a reproducible environment:"
      echo "  ./scripts/tools.sh shell"
      if command -v bash >/dev/null 2>&1 && [[ -f "${script_dir}/tools-install.sh" || -f "${script_dir}/brew-install.sh" ]]; then
        local auto_install=0
        if [[ "${AUTO_INSTALL:-}" == "1" || "${AUTO_INSTALL:-}" == "true" || "${2:-}" == "--auto-install" ]]; then
          auto_install=1
        fi
        if [[ $auto_install -eq 1 ]]; then
          echo "AUTO_INSTALL enabled — running installer non-interactively..."
          if [[ "$(uname -s)" == "Darwin" && -f "${script_dir}/brew-install.sh" ]]; then
            bash "${script_dir}/brew-install.sh" --yes --accept-driver-permissions
          else
            bash "${script_dir}/tools-install.sh" --yes
          fi
          echo "Re-running tools check..."
          if ! "${script_dir}/tools.sh" check; then
            error_exit "Prerequisite check failed after installer. Please resolve remaining issues and try again."
          fi
        else
          read -r -p "Would you like to run the interactive installer to provision prerequisites now? [y/N]: " RUN_INSTALL
          if [[ "$RUN_INSTALL" =~ ^[Yy]$ ]]; then
            echo "Running installer helper..."
            if [[ "$(uname -s)" == "Darwin" && -f "${script_dir}/brew-install.sh" ]]; then
              bash "${script_dir}"/brew-install.sh
            else
              bash "${script_dir}/tools-install.sh"
            fi
            echo "Re-running tools check..."
            if ! "${script_dir}/tools.sh" check; then
              error_exit "Prerequisite check failed after installer. Please resolve remaining issues and try again."
            fi
          else
            error_exit "Prerequisite check failed."
          fi
        fi
      else
        error_exit "Prerequisite check failed."
      fi
    fi
    echo "✅ All required tools are available."
  else
    for tool in kubectl jq base64 terraform; do
      if ! command -v $tool &>/dev/null; then
        error_exit "$tool is required but not installed. Please install $tool and try again."
      fi
    done
    echo "✅ All required tools are installed."
  fi
}
