#!/bin/bash
set -euo pipefail

usage() {
    echo " "
    echo "*************"
    echo "infra-boot.sh"
    echo "*************"
    echo " "
    echo "DESCRIPTION"
    echo "Create new infrastructure for Fawkes platform. Supports AWS (Docker Swarm or EKS), Minikube/local K8s, Azure, and GCP."
    echo " "
    echo "PRE-REQUISITES: "
    echo "1) You must have the CLI tools for your target cloud (aws, az, gcloud) and/or minikube/kubectl installed and configured."
    echo "2) For AWS, you must have defined a key-pair in the AWS account and region."
    echo " "
    echo "ARGUMENTS:"
    echo "-p [provider]           (required) Target provider: aws|minikube|azure|gcp"
    echo "-k [key-pair-name]      (AWS only) AWS key pair for EC2 instances"
    echo "-w [aws-instance-type]  (AWS only) Instance type for worker nodes"
    echo "-m [aws-instance-type]  (AWS only) Instance type for manager nodes"
    echo "-e [environment-name]   (required) Swarm environment name (e.g., 'platform', 'prod')"
    echo "-h                      Show this help message"
    echo ""
}

# Parse arguments
PROVIDER=""
KEYPAIR_NAME=""
WORKER_TYPE=""
MANAGER_TYPE=""
ENV_NAME=""

while getopts ":p:e:k:w:m:h" opt; do
  case $opt in
    p) PROVIDER="$OPTARG" ;;
    k) KEYPAIR_NAME="$OPTARG" ;;
    w) WORKER_TYPE="$OPTARG" ;;
    m) MANAGER_TYPE="$OPTARG" ;;
    e) ENV_NAME="$OPTARG" ;;
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

case "$PROVIDER" in
  aws)
    if [[ -z "$KEYPAIR_NAME" || -z "$WORKER_TYPE" || -z "$MANAGER_TYPE" ]]; then
      echo "Error: -k, -w, and -m are required for AWS."
      usage
      exit 1
    fi

    INFRA_BUCKET_NAME="infra-boot-$ENV_NAME"
    if ! aws s3 mb "s3://$INFRA_BUCKET_NAME"; then
        echo "Failed to create S3 bucket $INFRA_BUCKET_NAME"
        exit 1
    fi

    aws s3api put-bucket-versioning --bucket "$INFRA_BUCKET_NAME" --versioning-configuration Status=Enabled
    aws s3 sync . "s3://$INFRA_BUCKET_NAME"
    aws s3 ls "s3://$INFRA_BUCKET_NAME"

    if ! aws cloudformation create-stack \
        --stack-name platform \
        --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl \
        --capabilities CAPABILITY_IAM \
        --parameters ParameterKey=KeyName,ParameterValue="$KEYPAIR_NAME" \
                     ParameterKey=InstanceType,ParameterValue="$WORKER_TYPE" \
                     ParameterKey=ManagerInstanceType,ParameterValue="$MANAGER_TYPE" \
                     ParameterKey=EnableCloudStorEfs,ParameterValue=yes; then
        echo "CloudFormation stack creation failed."
        exit 1
    fi

    echo "Waiting for platform stack to be created..."
    sleep 4m
    aws cloudformation wait stack-create-complete --stack-name platform

    echo "Platform front DNS:"
    aws cloudformation describe-stacks --stack-name platform \
        --query 'Stacks[0].Outputs[?OutputKey==`DefaultDNSTarget`].OutputValue' --output text

    echo "Platform Manager IPs:"
    aws ec2 describe-instances --filters "Name=tag:Name,Values=platform-Manager" \
        --output text --query 'Reservations[*].Instances[*].PublicIpAddress'
    ;;
  minikube)
    echo "Provisioning local Minikube cluster..."
    if ! command -v minikube &>/dev/null; then
      echo "Error: minikube is not installed."
      exit 1
    fi
    minikube start --profile "$ENV_NAME"
    kubectl config use-context "minikube"
    echo "Minikube cluster '$ENV_NAME' is ready."
    ;;
  azure)
    echo "Provisioning Azure Kubernetes Service (AKS) cluster..."
    if ! command -v az &>/dev/null; then
      echo "Error: Azure CLI (az) is not installed."
      exit 1
    fi
    # Example: az aks create --resource-group ... --name ...
    echo "TODO: Add AKS provisioning logic here."
    ;;
  gcp)
    echo "Provisioning Google Kubernetes Engine (GKE) cluster..."
    if ! command -v gcloud &>/dev/null; then
      echo "Error: Google Cloud CLI (gcloud) is not installed."
      exit 1
    fi
    # Example: gcloud container clusters create ...
    echo "TODO: Add GKE provisioning logic here."
    ;;
  *)
    echo "Error: Unsupported provider '$PROVIDER'."
    usage
    exit 1
    ;;
esac

echo "Infrastructure provisioning complete for provider: $PROVIDER"