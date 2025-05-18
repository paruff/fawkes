#!/usr/bin/env bash
set -euo pipefail

# bootinfra.sh - Unified infrastructure bootstrap for Fawkes (AWS, Minikube, Azure, GCP-ready)

usage() {
  echo ""
  echo "Fawkes Infrastructure Bootstrap"
  echo ""
  echo "Usage: $0 -p <provider> -e <environment> [options]"
  echo ""
  echo "Options:"
  echo "  -p <provider>         Target provider: aws | minikube | azure | gcp"
  echo "  -e <environment>      Environment name (e.g., dev, stage, prod, platform)"
  echo "  -k <keypair>          (AWS only) EC2 key pair name"
  echo "  -w <worker-type>      (AWS only) Worker node instance type"
  echo "  -m <manager-type>     (AWS only) Manager node instance type"
  echo "  -h                    Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 -p aws -e dev -k mykey -w t3.medium -m t3.large"
  echo "  $0 -p minikube -e dev"
  echo ""
}

# Parse arguments
PROVIDER=""
ENV_NAME=""
KEYPAIR_NAME=""
WORKER_TYPE=""
MANAGER_TYPE=""

while getopts ":p:e:k:w:m:h" opt; do
  case $opt in
    p) PROVIDER="$OPTARG" ;;
    e) ENV_NAME="$OPTARG" ;;
    k) KEYPAIR_NAME="$OPTARG" ;;
    w) WORKER_TYPE="$OPTARG" ;;
    m) MANAGER_TYPE="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$PROVIDER" || -z "$ENV_NAME" ]]; then
  echo "Error: -p (provider) and -e (environment) are required."
  usage
  exit 1
fi

# Tool checks per provider
check_tools() {
  for tool in "$@"; do
    if ! command -v "$tool" &>/dev/null; then
      echo "Error: $tool is not installed or not in PATH."
      exit 1
    fi
  done
}

case "$PROVIDER" in
  aws)
    check_tools terraform kubectl aws
    if [[ -z "$KEYPAIR_NAME" || -z "$WORKER_TYPE" || -z "$MANAGER_TYPE" ]]; then
      echo "Error: -k, -w, and -m are required for AWS."
      usage
      exit 1
    fi

    terraform init
    terraform fmt
    terraform plan
    terraform apply --auto-approve

    REGION=$(terraform output -raw region)
    CLUSTER_NAME=$(terraform output -raw cluster_name)

    if [[ -n "$REGION" && -n "$CLUSTER_NAME" ]]; then
      aws eks --region "$REGION" update-kubeconfig --name "$CLUSTER_NAME"
    else
      echo "Error: REGION or CLUSTER_NAME output is missing from Terraform."
      exit 1
    fi

    if terraform output config_map_aws_auth &>/dev/null; then
      mkdir -p /tmp
      terraform output config_map_aws_auth > /tmp/configmap.yml
      kubectl apply -f /tmp/configmap.yml
    fi
    ;;

  minikube)
    check_tools minikube kubectl
    if [[ "$OSTYPE" == "darwin"* ]]; then
      DRIVER="docker"
    else
      DRIVER="virtualbox"
    fi
    echo "Starting minikube with driver: $DRIVER"
    minikube start --profile "$ENV_NAME" --driver="$DRIVER"
    kubectl config use-context "$ENV_NAME" || kubectl config use-context "minikube"
    ;;

  azure)
    check_tools az terraform kubectl
    echo "Azure support is planned. Please see the documentation or contribute!"
    # Placeholder for Azure best practices and IaC
    # azure_development-get_best_practices
    exit 1
    ;;

  gcp)
    check_tools gcloud terraform kubectl
    echo "GCP support is planned. Please see the documentation or contribute!"
    exit 1
    ;;

  *)
    echo "Error: Unsupported provider '$PROVIDER'."
    usage
    exit 1
    ;;
esac

# Create namespaces if they do not exist
for ns in fawkes dev stage prod; do
  if ! kubectl get namespace "$ns" &>/dev/null; then
    kubectl create namespace "$ns"
  else
    echo "Namespace '$ns' already exists."
  fi
done

echo "Infrastructure and namespaces are ready for provider: $PROVIDER"

# --- Infrastructure Testing Section ---
echo "Running infrastructure tests..."

if command -v inspec &>/dev/null; then
  if [ -d "./test/integration/default" ]; then
    inspec exec ./test/integration/default || {
      echo "Infrastructure tests failed."
      exit 1
    }
    echo "Infrastructure tests passed."
  else
    echo "No InSpec tests found in ./test/integration/default. Skipping tests."
  fi
elif command -v kitchen &>/dev/null; then
  kitchen test || {
    echo "Kitchen tests failed."
    exit 1
  }
  echo "Kitchen tests passed."
else
  echo "No infrastructure testing tool (inspec or kitchen) found. Skipping tests."
fi

echo "Infrastructure provisioning and testing complete for provider: $PROVIDER"
