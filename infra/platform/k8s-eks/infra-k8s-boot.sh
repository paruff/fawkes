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

#!/usr/bin/env bash

terraform init
terraform fmt
terraform plan -var-file="starter.tfvars"
terraform apply --auto-approve

# Configure kubectl Configure
cp kubeconfig_* $HOME/.kube/config
cp kubeconfig_* $HOME/.kube/

export  KUBECONFIG_SAVED=$KUBECONFIG
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config


# Helm 
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller --tiller-tls-verify

helm install stable/kubernetes-dashboard --name dashboard-demo


# Helm up basic
# kubectl create namespace pipeline
# # Jenkins
# helm install --namespace=pipeline stable/jenkins --name jenkins
# # kubectl get svc --namespace pipeline -w jenkins
# # capture url and admin password
##
# printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export SERVICE_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login
# # list plugins



# helm install --namespace=pipeline stable/sonarqube --name sonarqube
# # Configure auth, uid: admin, pw:admin
# export SERVICE_IP=$(kubectl get svc --namespace pipeline sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# echo http://$SERVICE_IP:9000
# # add plugins

# helm install --namespace=pipeline stable/sonatype-nexus --name nexus
## where is the url
## uid: admin, pw: admin123


# helm install --namespace=pipeline stable/selenium --name selenium
## internal URL - http://selenium-selenium-hub.pipeline:4444

# helm install --namespace=pipeline stable/spinnaker --name spinnaker
# # Satisfied
# helm install --namespace=pipeline stable/prometheus --name prometheus

# helm install --namespace=pipeline stable/elastic-stack --name elk

# helm install --namespace=pipeline stable/anchore-engine --name anchore

# helm install --namespace=pipeline stable/ --name 


# # Delight







