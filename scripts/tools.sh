#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
NIX_FLAKE_PATH="${REPO_ROOT}/infra/nix"

function usage() {
  cat <<EOF
Usage: $0 <command>

Commands:
  check    - verify required CLI tools are available (using Nix devShell if available)
  shell    - open an interactive Nix dev shell (if Nix and flake available)
  install  - interactive installer helper (on macOS will use Brewfile installer)
  help     - show this message

Examples:
  ./scripts/tools.sh check
  ./scripts/tools.sh shell
EOF
}

if [[ ${#} -lt 1 ]]; then
  usage
  exit 1
fi

CMD="$1"

function ensure_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    echo "Nix is not installed. Please install Nix: https://nixos.org/download.html"
    return 2
  fi
  return 0
}

case "$CMD" in
  check)
    # If Nix flake exists and nix is installed, run checks inside the devShell; otherwise check host
    if [[ -f "${NIX_FLAKE_PATH}/flake.nix" && $(command -v nix >/dev/null 2>&1; echo $?) -eq 0 ]]; then
      echo "Running checks inside Nix devShell from ${NIX_FLAKE_PATH}..."
      nix shell "${NIX_FLAKE_PATH}#default" -c bash -lc '
        set -euo pipefail
        MISSING=0
        for tool in kubectl helm terraform tflint terraform-docs tfsec kubeconform kustomize gitleaks trivy argocd jq yq git docker pre-commit; do
          if ! command -v "$tool" >/dev/null 2>&1; then
            echo "MISSING: $tool"
            MISSING=1
          else
            echo "OK: $tool -> $(command -v $tool)"
          fi
        done
        exit $MISSING
      '
      exit $?
    else
      if [[ -f "${NIX_FLAKE_PATH}/flake.nix" ]]; then
        echo "Nix flake found at ${NIX_FLAKE_PATH} but 'nix' is not installed. Continuing with host checks..."
      else
        echo "No Nix flake at ${NIX_FLAKE_PATH}; checking host for required tools..."
      fi
        MISSING=0
        for tool in kubectl helm terraform tflint terraform-docs tfsec kubeconform kustomize gitleaks trivy argocd jq yq git docker pre-commit; do
        if ! command -v "$tool" >/dev/null 2>&1; then
          echo "MISSING: $tool"
          MISSING=1
        else
          echo "OK: $tool -> $(command -v $tool)"
        fi
      done
      exit $MISSING
    fi
    ;;

  install)
    # On macOS prefer the Brewfile installer; otherwise fall back to tools-install.sh
    if [[ "$(uname -s)" == "Darwin" && -f "${SCRIPT_DIR}/brew-install.sh" ]]; then
      echo "Running macOS Brewfile installer: ${SCRIPT_DIR}/brew-install.sh"
      exec bash "${SCRIPT_DIR}/brew-install.sh"
    elif [[ -f "${SCRIPT_DIR}/tools-install.sh" ]]; then
      echo "Running installer helper: ${SCRIPT_DIR}/tools-install.sh"
      exec bash "${SCRIPT_DIR}/tools-install.sh"
    else
      echo "No installer helper found (brew-install.sh or tools-install.sh) in ${SCRIPT_DIR}"
      exit 2
    fi
    ;;

  shell)
    ensure_nix || exit 2
    if [[ -f "${NIX_FLAKE_PATH}/flake.nix" ]]; then
      echo "Entering Nix devShell from ${NIX_FLAKE_PATH}... (ctrl-d to exit)"
      exec nix develop "${NIX_FLAKE_PATH}"
    else
      echo "No flake found at ${NIX_FLAKE_PATH}. Create a flake.nix with a devShell or run 'nix shell' manually."
      exit 3
    fi
    ;;

  help|--help|-h)
    usage
    ;;

  *)
    echo "Unknown command: $CMD"
    usage
    exit 1
    ;;
esac
