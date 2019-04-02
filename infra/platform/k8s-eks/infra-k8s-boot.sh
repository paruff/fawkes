# infra-k8s-boot.sh

# $EKS_SERVICE_ROLE
# EKS_SUBNET_IDS
# EKS_SECURITY_GROUPS

# aws eks create-cluster \
#   --name k8s-workshop \
#   --role-arn $EKS_SERVICE_ROLE \
#   --resources-vpc-config subnetIds=${EKS_SUBNET_IDS},securityGroupIds=${EKS_SECURITY_GROUPS} \
#   --kubernetes-version 1.10
  

#   aws cloudformation create-stack \
#   --stack-name k8s-workshop-worker-nodes \
#   --template-url https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml \
#   --capabilities "CAPABILITY_IAM" \
#   --parameters "[{\"ParameterKey\": \"KeyName\", \"ParameterValue\": \"${AWS_STACK_NAME}\"},
#                  {\"ParameterKey\": \"NodeImageId\", \"ParameterValue\": \"${EKS_WORKER_AMI}\"},
#                  {\"ParameterKey\": \"ClusterName\", \"ParameterValue\": \"k8s-workshop\"},
#                  {\"ParameterKey\": \"NodeGroupName\", \"ParameterValue\": \"k8s-workshop-nodegroup\"},
#                  {\"ParameterKey\": \"ClusterControlPlaneSecurityGroup\", \"ParameterValue\": \"${EKS_SECURITY_GROUPS}\"},
#                  {\"ParameterKey\": \"VpcId\", \"ParameterValue\": \"${EKS_VPC_ID}\"},
#                  {\"ParameterKey\": \"Subnets\", \"ParameterValue\": \"${EKS_SUBNET_IDS}\"}]"

terraform plan
terraform fmt

terraform plan

