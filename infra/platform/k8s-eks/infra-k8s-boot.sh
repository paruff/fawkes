#!/usr/bin/env bash
# infra-k8s-boot.sh
## TODO
# conditional helm install and update based on does it exist
# break up cloud provider terraform k8s up
# os or shell conditional installs of packages mac, win , yum, apt-get?

case "$OSTYPE" in
#  linux*)   machine=Linux;;
  darwin*)  machine=Mac;; 
  win*)     machine=Windows;;
  msys*)    machine=GBash ;;
#  cygwin*)  machine=Cygwin;;
#  bsd*)     machine=BSD;;
  *)        echo "unknown: $OSTYPE" ;;
esac

echo ${machine}

if [ ${machine} = "Mac" ]; 
then
../../workspace/space-setup-macosx.sh
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

fi
# now for windows 10 running git bash
# TODO define and lock the versions to working versions 
if [ ${machine} = "GBash" ]; 
then
../../workspace/space-setup-win10.ps1
if ! aws-iam-authenticator -h; then
# this aim-authorize-
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
#   Linux: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
#    MacOS: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/darwin/amd64/aws-iam-authenticator
#    Windows: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/windows/amd64/aws-iam-authenticator.exe
 curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/windows/amd64/aws-iam-authenticator.exe
 openssl sha1 -sha256 aws-iam-authenticator.exe
 chmod +x ./aws-iam-authenticator.exe
 mkdir $HOME/bin && cp ./aws-iam-authenticator.exe $HOME/bin/aws-iam-authenticator.exe && export PATH=$HOME/bin:$PATH
 echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile
fi

fi

# exit
# This is code to create a k8s eks using cloudformation, seems to work in us-east-2
# export StackID=fawkes
# export KeyPairName=tads-eks-use2
# export 
#
# aws cloudformation create-stack --stack-name fawkes --template-body https://s3.amazonaws.com/aws-quickstart/quickstart-amazon-eks/templates/amazon-eks-master.template.yaml --parameters ParameterKey=KeyPairName,ParameterValue=tads-eks-use2 ParameterKey=AvailabilityZones,ParameterValue=us-east-2a\\,us-east-2b\\,us-east-2c ParameterKey=RemoteAccessCIDR,ParameterValue=0.0.0.0/0 ParameterKey=ClusterAutoScaler,ParameterValue=Enabled --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND
# aws cloudformation wait stack-create-complete --stack-name fawkes
# aws cloudformation describe-stacks --stack-name fawkes --query "Stacks[0].Outputs[?OutputKey=='BastionIP'].OutputValue" --output text | read BastionIP
# ssh -o "StrictHostKeyChecking no"  -i ~/.ssh/$KeyPairName ec2-user@$BastionIP
# scp -r . -i ~/.ssh/$KeyPairName ec2-user@$BastionIP:.

terraform init
terraform fmt
terraform plan
terraform apply --auto-approve

# Configure kubectl Configure
mkdir -p $HOME/.kube
# terraform output kubeconfig > ~/.kube/config

cp kubeconfig_* $HOME/.kube/config
cp kubeconfig_* $HOME/.kube/

# move to localk8s config
# mkdir -p /tmp
# terraform output config_map_aws_auth > /tmp/configmap.yml
# kubectl apply -f /tmp/configmap.yml

export  KUBECONFIG_SAVED=$KUBECONFIG
export KUBECONFIG=$HOME/.kube/config


# Helm 
# # kubectl apply -f tiller-user.yaml
# kubectl -n kube-system create serviceaccount tiller
# kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# helm init --service-account tiller --history-max 200
 helm init --history-max 200
# --tiller-tls-verify
# kubectl rollout status -h
# kubectl rollout status deployment tiller-deploy -n kube-system

helm install --wait stable/kubernetes-dashboard --name dashboard-demo

kubectl create namespace pipeline

# Helm up basic
# # Jenkins
  kubectl apply -f jenkins/service-account.yaml
  helm install --namespace=pipeline stable/jenkins --name jenkins -f jenkins/values.yaml --wait 
echo "Jenkins admin password:"
printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
export JENKINS_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Jenkins LB URL"http://$JENKINS_IP:8080/login
# printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login

# # Sonarqube
helm install --name sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=pipeline --wait
helm test sonarqube --cleanup
# get latest load balancer path to sonarqube chart
export SERVICE_IP=$(kubectl get svc --namespace pipeline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP:9000

helm install --namespace=pipeline stable/sonatype-nexus --name registry --set nexus.service.type=LoadBalancer --wait
## where is the url? change nexus.service.type to loadbalancer --set nexus.service.type=LoadBalancer
## uid: admin, pw: admin123
## I don't seem to have access externally

helm install --namespace=pipeline stable/selenium --name selenium --set chromeDebug.enabled=true --set .enabled=true --wait
## internal URL - http://selenium-selenium-hub.pipeline:4444

helm install --namespace=pipeline stable/spinnaker --name spinnaker --wait

# # Satisfied
kubectl create secret generic --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
helm install --name prometheus --namespace pipeline -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait

# Setup EFK-stack (elasticsearch, fluent-bit, and kibana)
helm install --name elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=pipeline --wait
helm test elk --cleanup

# # Delight
# TODO: mssheldon - 05/02/2019; logging is way too high for some reason.  Circle back on this later.
# helm install --namespace=pipeline stable/anchore-engine --name anchore --wait

helm install --namespace=pipeline --name jmeter stable/distributed-jmeter --wait

cd hygieia
./hygieia-reinstall.sh
cd ..

# helm install --namespace=pipeline stable/ --name 
