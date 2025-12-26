#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/flags.sh
# Purpose: Command-line flag parsing
# =============================================================================

usage() {
  echo "Usage: $0 [--provider local|aws|azure|gcp] [--cluster-name NAME] [--region REGION|--location LOCATION] [--only-cluster|--only-apps|--skip-cluster] [--dry-run] [--resume] [--verbose] [--access] <environment|cleanup|destroy>"
  echo "  environment: local | dev | stage | production"
  echo "  cleanup: remove ArgoCD and Fawkes resources for a fresh start"
  echo "  destroy: run Terraform destroy for the selected provider"
  echo "  flags:"
  echo "    --provider|-p        One of local|aws|azure|gcp"
  echo "    --cluster-name|-n    Cluster name for provider Terraform (TF_VAR_cluster_name)"
  echo "    --region|-r          Region for AWS/GCP (TF_VAR_region)"
  echo "    --location           Location for Azure (TF_VAR_location)"
  echo "    --prefer-minikube    Prefer minikube over docker-desktop for local"
  echo "    --prefer-docker-desktop Prefer docker-desktop over minikube for local (default)"
  echo "    --only-cluster       Provision cluster only (skip Argo CD & apps)"
  echo "    --only-apps          Deploy Argo CD & apps only (skip cluster)"
  echo "    --skip-cluster       Alias for --only-apps"
  echo "    --dry-run            Plan-only (no apply), print intended actions"
  echo "    --resume             Attempt to resume a previous run"
  echo "    --verbose|-v         Verbose output (set -x)"
  echo "    --access             Show access summary only (no deployment)"
  exit 1
}

parse_flags() {
  local argv=("$@")
  local i=0
  while [[ $i -lt ${#argv[@]} ]]; do
    local arg="${argv[$i]}"
    case "$arg" in
      --provider | -p)
        local next_index=$((i + 1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--provider requires a value: local|aws|azure|gcp"
        fi
        PROVIDER="${argv[$next_index]}"
        i=$((i + 2))
        continue
        ;;
      --cluster-name | -n)
        local next_index=$((i + 1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--cluster-name requires a value"
        fi
        CLUSTER_NAME="${argv[$next_index]}"
        i=$((i + 2))
        continue
        ;;
      --region | -r)
        local next_index=$((i + 1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--region requires a value"
        fi
        REGION="${argv[$next_index]}"
        i=$((i + 2))
        continue
        ;;
      --location)
        local next_index=$((i + 1))
        if [[ $next_index -ge ${#argv[@]} ]]; then
          error_exit "--location requires a value"
        fi
        LOCATION="${argv[$next_index]}"
        i=$((i + 2))
        continue
        ;;
      --only-cluster)
        ONLY_CLUSTER=1
        i=$((i + 1))
        continue
        ;;
      --only-apps)
        ONLY_APPS=1
        i=$((i + 1))
        continue
        ;;
      --skip-cluster)
        SKIP_CLUSTER=1
        i=$((i + 1))
        continue
        ;;
      --dry-run)
        DRY_RUN=1
        i=$((i + 1))
        continue
        ;;
      --resume)
        RESUME=1
        i=$((i + 1))
        continue
        ;;
      --verbose | -v)
        VERBOSE=1
        i=$((i + 1))
        continue
        ;;
      --prefer-minikube)
        PREFER_MINIKUBE=1
        i=$((i + 1))
        continue
        ;;
      --prefer-docker-desktop)
        PREFER_DOCKER=1
        i=$((i + 1))
        continue
        ;;
      --access)
        SHOW_ACCESS_ONLY=1
        i=$((i + 1))
        continue
        ;;
      --help | -h)
        usage
        ;;
      *)
        if [[ ! "$arg" =~ ^- && -z "$ENV" && "$arg" != "clean" && "$arg" != "cleanup" ]]; then
          ENV="$arg"
        fi
        i=$((i + 1))
        ;;
    esac
  done

  # Derive default provider from ENV for backward-compatibility
  if [[ -z "${PROVIDER}" && "$ENV" == "local" ]]; then
    PROVIDER="local"
  fi

  # Validate provider
  if [[ -n "${PROVIDER}" ]] && ! [[ "${PROVIDER}" =~ ^(local|aws|azure|gcp)$ ]]; then
    error_exit "Unknown provider '${PROVIDER}'. Expected one of: local, aws, azure, gcp."
  fi

  # Validate mutually exclusive flags
  if [[ $ONLY_CLUSTER -eq 1 && ($ONLY_APPS -eq 1 || $SKIP_CLUSTER -eq 1) ]]; then
    error_exit "--only-cluster cannot be combined with --only-apps/--skip-cluster"
  fi
  if [[ ${PREFER_MINIKUBE:-0} -eq 1 && ${PREFER_DOCKER:-0} -eq 1 ]]; then
    error_exit "--prefer-minikube cannot be combined with --prefer-docker-desktop"
  fi
}
