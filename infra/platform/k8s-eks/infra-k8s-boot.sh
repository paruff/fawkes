#!/usr/bin/env bash
# infra-k8s-boot.sh

if ! brew -v; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# this assumes terraform is installed
if ! terraform -v; then
 brew install terraform
fi
if ! kubectl version; then
  brew install kubernetes-cli
fi
if ! helm version; then
  brew install kubernetes-helm
fi

if ! aws-iam-authenticator -h; then
# this aim-authorize-
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
#   Linux: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
#    MacOS: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/darwin/amd64/aws-iam-authenticator
#    Windows: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/windows/amd64/aws-iam-authenticator.exe
 curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/darwin/amd64/aws-iam-authenticator
 openssl sha1 -sha256 aws-iam-authenticator
 chmod +x ./aws-iam-authenticator
 mkdir $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$HOME/bin:$PATH
 echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile
fi


terraform init
terraform fmt
terraform plan
terraform apply --auto-approve

# Configure kubectl Configure
cp kubeconfig_* $HOME/.kube/config
cp kubeconfig_* $HOME/.kube/

export  KUBECONFIG_SAVED=$KUBECONFIG
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config


# Helm 
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller 
# --tiller-tls-verify
# kubectl rollout status -h
kubectl rollout status deployment tiller-deploy -n kube-system

helm install --wait stable/kubernetes-dashboard --name dashboard-demo

# Helm up basic
# kubectl create namespace pipeline
# # Jenkins
helm install --namespace=pipeline stable/jenkins --name jenkins --wait --set Master.InstallPlugins=[kubernetes:1.14.0 workflow-aggregator:2.6 credentials-binding:1.17 git:3.9.1 workflow-job:2.31]
# # kubectl get svc --namespace pipeline -w jenkins
# # capture url and admin password
##
# printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login
# # list plugins

helm install --namespace=pipeline stable/sonarqube --name sonarqube --wait
# # Configure auth, uid: admin, pw:admin
# export SONAR_SERVICE_IP=$(kubectl get svc --namespace pipeline sonarqube-sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# echo http://$SERVICE_IP:9000
# # add plugins

helm install --namespace=pipeline stable/sonatype-nexus --name nexus --set nexus.service.type=LoadBalancer --wait
## where is the url? change nexus.service.type to loadbalancer --set nexus.service.type=LoadBalancer
## uid: admin, pw: admin123
## I don't seem to have access externally

helm install --namespace=pipeline stable/selenium --name selenium
## internal URL - http://selenium-selenium-hub.pipeline:4444

helm install --namespace=pipeline stable/spinnaker --name spinnaker --wait
# # Satisfied
helm install --namespace=pipeline stable/prometheus --name prometheus --wait

helm install --namespace=pipeline stable/elastic-stack --name elk --wait

 helm install --namespace=pipeline stable/anchore-engine --name anchore --wait

# helm install --namespace=pipeline stable/ --name 

helm install --namespace=pipeline --name jmeter stable/distributed-jmeter --wait

# # Delight







