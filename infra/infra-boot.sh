#!/bin/bash
# ./infra-boot.sh -k platform-use1 -w m4.xlarge -m t2.medium -e dr1
# ssh -i ~/.ssh/platform-use1 docker@10...
# scp -i ~/.ssh/platform-use1 -r platform/* docker@10...:
# ssh -i ~/.ssh/platform-use1 docker@10...
# docker stack deploy --compose-file docker-compose-swarm.yml platform


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
    echo "1) You must have the AWS CLI installed on the machine where you're running"
    echo "   this script; you must have configured it for the account / region where you want to install"
    echo "   the cluster."
    echo "2) You must have defined a key-pair in the AWS account and region in which you're"
    echo "   installing the cluster"
    echo " "
    echo "ARGUMENTS:"
    echo "-k [key-pair-name] is required argument identifying the AWS key pair to be used on the EC2"
    echo "      instances in the cluster"
    echo "-w [aws-instance-type] is a required argument identifying what instance type to be used for"
    echo "      the worker instances in the cluster"
    echo "-m [aws-instance-type] is a required argument identifying what instance type to be used for"
    echo "      the swarm cluster manager(s)"
    echo "-e [environment-name] is a required name for the swarm, e.g., 'platform' or 'prod'"
    ECHO "-h to display this help script"
    echo ""
}

while getopts ":e:k:w:m:h" opt; do
  case $opt in
    k) KEYPAIR_NAME="$OPTARG" ;;
    w) WORKER_TYPE="$OPTARG" ;;
    m) MANAGER_TYPE="$OPTARG" ;;
    e) ENV_NAME="$OPTARG" ;;
    \?) 
      echo "Invalid option - $OPTARG"
      exit 1
      ;;
    *) 
      usage 
      exit 1
      ;;
    h)
      usage
      exit 1
      ;;
  esac
done

# Store this directory's contents in an S3 bucket so we have future access to what version
# of the scripts were used to create these stacks.
INFRA_BUCKET_NAME=infra-boot-$ENV_NAME
aws s3 mb s3://$INFRA_BUCKET_NAME
aws s3api put-bucket-versioning --bucket $INFRA_BUCKET_NAME --versioning-configuration Status=Enabled
aws s3 sync . s3://$INFRA_BUCKET_NAME
aws s3 ls s3://$INFRA_BUCKET_NAME

# let share this key with the rest of the US regions
# https://fedoramagazine.org/ssh-key-aws-regions/
# AWS_REGION="us-east-1 us-east-2 us-west-1 us-west-2"
# for each in ${AWS_REGION} ; do aws ec2 import-key-pair --key-name $KEYPAIR_NAME --public-key-material file://~/.ssh/aws.pub --region each ; done

# Create the three environments
aws cloudformation create-stack --stack-name platform --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl --capabilities CAPABILITY_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEYPAIR_NAME ParameterKey=InstanceType,ParameterValue=$WORKER_TYPE ParameterKey=ManagerInstanceType,ParameterValue=$MANAGER_TYPE ParameterKey=EnableCloudStorEfs,ParameterValue=yes
aws cloudformation create-stack --stack-name verfut-at --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl --capabilities CAPABILITY_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEYPAIR_NAME ParameterKey=InstanceType,ParameterValue=$WORKER_TYPE ParameterKey=ManagerInstanceType,ParameterValue=$MANAGER_TYPE ParameterKey=EnableCloudStorEfs,ParameterValue=yes ParameterKey=ClusterSize,ParameterValue=3 ParameterKey=ManagerSize,ParameterValue=3
aws cloudformation create-stack --stack-name verfut-demo --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl --capabilities CAPABILITY_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEYPAIR_NAME ParameterKey=InstanceType,ParameterValue=$WORKER_TYPE ParameterKey=ManagerInstanceType,ParameterValue=$MANAGER_TYPE ParameterKey=EnableCloudStorEfs,ParameterValue=yes ParameterKey=ClusterSize,ParameterValue=3 ParameterKey=ManagerSize,ParameterValue=3
# aws cloudformation create-stack --stack-name jenkins-ecs --template-url file://platform/jenkins-ecs.yaml --capabilities CAPABILITY_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEYPAIR_NAME ParameterKey=InstanceType,ParameterValue=m4.large ParameterKey=EcsImageId,ParameterValue=ami-028a9de0a7e353ed9 ParameterKey=PublicAccessCIDR,ParameterValue=0.0.0.0/0 ParameterKey=AvailabilityZone1,ParameterValue=us-east-2a ParameterKey=AvailabilityZone2,ParameterValue=us-east-2b


# SHOULDN'T NEED THIS: DEMO OUT OF THE APP TESTING ENVIRONMENT
#aws cloudformation create-stack --stack-name project-demo --template-url https://editions-us-east-1.s3.amazonaws.com/aws/stable/Docker.tmpl --capabilities CAPABILITY_IAM --parameters ParameterKey=KeyName,ParameterValue=platform-use1 ParameterKey=InstanceType,ParameterValue=t2.micro ParameterKey=ManagerInstanceType,ParameterValue=t2.micro

 echo "Waiting for platform to be created..."
 sleep 4m
aws cloudformation wait stack-create-complete --stack-name platform 
echo "Platform front DNS="
aws cloudformation describe-stacks --stack-name platform --query 'Stacks[0].Outputs[?OutputKey==`DefaultDNSTarget`].OutputValue' --output text
echo "Platform ManagerIPs="
aws ec2 describe-instances --filters 'Name=tag:Name,Values=platform-Manager'  --output text --query 'Reservations[*].Instances[*].PublicIpAddress'
## todo ssh in to first ip and scp docker-compose , docke stack deploy ...

aws cloudformation wait stack-create-complete --stack-name verfut-at
echo "AT front DNS="
aws cloudformation describe-stacks --stack-name verfut-at --query 'Stacks[0].Outputs[?OutputKey==`DefaultDNSTarget`].OutputValue' --output text
echo "Dev ManagerIPs="
aws ec2 describe-instances --filters 'Name=tag:Name,Values=verfut-at-Manager'  --output text --query 'Reservations[*].Instances[*].PublicIpAddress'

aws cloudformation wait stack-create-complete --stack-name verfut-demo 
echo "DEMO front DNS="
aws cloudformation describe-stacks --stack-name verfut-demo --query 'Stacks[0].Outputs[?OutputKey==`DefaultDNSTarget`].OutputValue' --output text
echo "AT ManagerIPs="
aws ec2 describe-instances --filters 'Name=tag:Name,Values=verfut-demo-Manager'  --output text --query 'Reservations[*].Instances[*].PublicIpAddress'

# aws cloudformation create-stack --stack-name platform-aelk --template-url https://s3.amazonaws.com/aws-cloudwatch/downloads/cloudwatch-logs-subscription-consumer/cwl-elasticsearch.template --capabilities CAPABILITY_IAM --parameters ParameterKey=KeyName,ParameterValue=$KEYPAIR_NAME ParameterKey=NginxUsername,ParameterValue=devsecops ParameterKey=NginxPassword,ParameterValue=1logger@CIS ParameterKey=LogGroupName,ParameterValue=platform-lg ParameterKey=LogFormat,ParameterValue=AWSCloudTrail ParameterKey=SubscriptionFilterPattern,ParameterValue=AWSCloudTrail 
