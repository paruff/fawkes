# infra-k8s-boot.sh

aws eks create-cluster \
  --name k8s-workshop \
  --role-arn $EKS_SERVICE_ROLE \
  --resources-vpc-config subnetIds=${EKS_SUBNET_IDS},securityGroupIds=${EKS_SECURITY_GROUPS} \
  --kubernetes-version 1.10
  