#!/bin/bash
set -euo pipefail

usage() {
    echo " "
    echo "*************"
    echo "infra-boot.sh"
    echo "*************"
    echo " "
    echo "DESCRIPTION"
    echo "Create new AWS VPC and deploy a Docker Swarm infrastructure. Uses the swarm template from"
    echo "Docker. Three different swarm clusters are created--one for the development tools (e.g.,"
    echo "Jenkins, Nexus, etc.), one for DEV deployment and one for application testing (AT)."
    echo " "
    echo "PRE-REQUISITES: "
    echo "1) You must have the AWS CLI installed and configured for the target account/region."
    echo "2) You must have defined a key-pair in the AWS account and region."
    echo " "
    echo "ARGUMENTS:"
    echo "-k [key-pair-name]      (required) AWS key pair for EC2 instances"
    echo "-w [aws-instance-type]  (required) Instance type for worker nodes"
    echo "-m [aws-instance-type]  (required) Instance type for manager nodes"
    echo "-e [environment-name]   (required) Swarm environment name (e.g., 'platform', 'prod')"
    echo "-h                      Show this help message"
    echo ""
}

# Parse arguments
KEYPAIR_NAME=""
WORKER_TYPE=""
MANAGER_TYPE=""
ENV_NAME=""

while getopts ":e:k:w:m:h" opt; do
  case $opt in
    k) KEYPAIR_NAME="$OPTARG" ;;
    w) WORKER_TYPE="$OPTARG" ;;
    m) MANAGER_TYPE="$OPTARG" ;;
    e) ENV_NAME="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
  esac
done

# Validate required arguments
if [[ -z "$KEYPAIR_NAME" || -z "$WORKER_TYPE" || -z "$MANAGER_TYPE" || -z "$ENV_NAME" ]]; then
    echo "Error: All arguments -k, -w, -m, and -e are required."
    usage
    exit 1
fi

# Store this directory's contents in an S3 bucket for versioning
INFRA_BUCKET_NAME="infra-boot-$ENV_NAME"
if ! aws s3 mb "s3://$INFRA_BUCKET_NAME"; then
    echo "Failed to create S3 bucket $INFRA_BUCKET_NAME"
    exit 1
fi

aws s3api put-bucket-versioning --bucket "$INFRA_BUCKET_NAME" --versioning-configuration Status=Enabled
aws s3 sync . "s3://$INFRA_BUCKET_NAME"
aws s3 ls "s3://$INFRA_BUCKET_NAME"

# Create the main platform stack
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

# TODO: SSH into first manager IP and deploy Docker stack

# Uncomment and adapt the following for additional environments as needed
# aws cloudformation create-stack --stack-name verfut-at ...
# aws cloudformation create-stack --stack-name verfut-demo ...