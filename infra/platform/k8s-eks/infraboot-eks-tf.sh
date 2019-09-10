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
kubectl apply -f tiller-user.yaml
# kubectl -n kube-system create serviceaccount tiller
# kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# helm init --service-account tiller --history-max 200
helm init --service-account tiller --history-max 200
# --tiller-tls-verify
# kubectl rollout status -h
kubectl rollout status --watch deployment/tiller-deploy -n kube-system

kubectl create namespace pline
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

sleep 5

helm install --wait stable/kubernetes-dashboard --name dashboard-demo

# Helm up basic
# # Jenkins
kubectl apply -f jenkins/service-account.yaml
helm install --namespace=pline stable/jenkins --name jenkins -f jenkins/values.yaml --wait 
echo "Jenkins admin password:"
printf $(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
export JENKINS_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Jenkins LB URL"http://$JENKINS_IP:8080/login
# printf $(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login

# # Sonarqube
helm install --name sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=pline --wait
helm test sonarqube --cleanup
# get latest load balancer path to sonarqube chart
export SERVICE_IP=$(kubectl get svc --namespace pline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP:9000

helm install --namespace=pline stable/sonatype-nexus --name registry --set nexus.service.type=LoadBalancer --wait
## where is the url? change nexus.service.type to loadbalancer --set nexus.service.type=LoadBalancer
## uid: admin, pw: admin123
## I don't seem to have access externally

helm install --namespace=pline stable/selenium --name selenium --set chromeDebug.enabled=true --set .enabled=true --wait
## internal URL - http://selenium-selenium-hub.pline:4444

helm install --namespace=pline stable/spinnaker --name spinnaker --wait

# # Satisfied
kubectl create secret generic --namespace pline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
helm install --name prometheus --namespace pline -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait

# Setup EFK-stack (elasticsearch, fluent-bit, and kibana)
helm install --name elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=pline --wait
helm test elk --cleanup

# # Delight
# TODO: mssheldon - 05/02/2019; logging is way too high for some reason.  Circle back on this later.
# helm install --namespace=pline stable/anchore-engine --name anchore --wait

helm install --namespace=pline --name jmeter stable/distributed-jmeter --wait

cd hygieia
./hygieia-reinstall.sh
cd ..

# helm install --namespace=pline stable/ --name 
