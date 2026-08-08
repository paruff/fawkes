# Homebrew Bundle — local dev tooling
# NOTE ON DETERMINISM: Homebrew does not support version pinning for most
# formulae (only a few versioned formulae exist: node@24, python@3.13, helm@3).
# The remaining tools below resolve to latest-stable at `brew bundle` time.
# Full deterministic local toolchains live in the Nix dev shell (see
# scripts/tools-install.sh) — infra/nix/flake.nix is a tracked follow-up.
# Keep the python major/minor aligned with CI (setup-python uses 3.13).
brew "git"
brew "jq"
brew "yq"
brew "node@24"          # pinned versioned formula (LTS 24)
brew "python@3.13"      # pinned versioned formula (matches CI 3.13)
brew "terraform"        # floats to latest-stable (no versioned formula)
brew "tflint"
brew "terraform-docs"
brew "tfsec"
brew "helm@3"           # pinned versioned formula (v3 line, CI uses v3)
brew "kubectl"
brew "kustomize"
brew "kubeconform"
brew "minikube"
brew "kind"
brew "gitleaks"
brew "trivy"
brew "argocd"
cask "docker"        # Docker Desktop (provides Docker engine and CLI)
