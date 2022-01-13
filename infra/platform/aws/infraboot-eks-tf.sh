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
fi

# now for windows 10 running git bash
# TODO define and lock the versions to working versions 
if [ ${machine} = "GBash" ]; 
then
../../workspace/space-setup-win10.ps1

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

kubectl create namespace pline
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

sleep 5

helm repo add k8s-dashboard https://kubernetes.github.io/dashboard
helm install fawkes-kubernetes-dashboard k8s-dashboard/kubernetes-dashboard --version 5.0.5

# helm install --wait stable/kubernetes-dashboard --name dashboard-demo

# Helm up basic
# # Jenkins
helm repo add jenkinsci https://charts.jenkins.io/
helm install fawkes-jenkins jenkinsci/jenkins --version 3.10.2
# change to LTS version
# add plugins for different pipelines


# kubectl apply -f jenkins/service-account.yaml
# helm install --namespace=pline stable/jenkins --name jenkins -f jenkins/values.yaml --wait 
# echo "Jenkins admin password:"
# printf $(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# export JENKINS_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

# echo "Jenkins LB URL"http://$JENKINS_IP:8080/login
# printf $(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login

# # Sonarqube
# helm install --name sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=pline --wait
# helm test sonarqube --cleanup
# get latest load balancer path to sonarqube chart
# export SERVICE_IP=$(kubectl get svc --namespace pline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
# echo http://$SERVICE_IP:9000

helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm install fawkes-sonarqube sonarqube/sonarqube 

helm install --namespace=pline stable/docker-registry  --name registry --wait 
# helm install --namespace=pline stable/sonatype-nexus --name registry --set nexus.service.type=LoadBalancer --wait
## uid: admin, pw: admin123
## I don't seem to have access externally

#SELENIUM 
helm repo add douban https://douban.github.io/charts/
helm install fawkes-selenium douban/selenium --version 1.3.0
# helm install --namespace=pline stable/selenium --name selenium --set chromeDebug.enabled=true --set .enabled=true --wait
## internal URL - http://selenium-selenium-hub.pline:4444

# spinnaker
# helm install --namespace=pline stable/spinnaker --name spinnaker --wait

helm repo add opsmx https://helmcharts.opsmx.com/
helm install fawkes-spinnaker opsmx/spinnaker --version 2.2.7

# # Satisfied
#PROMETHEUS
#  kubectl create secret generic --namespace pline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
# helm install --name prometheus --namespace pline -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install fawkes-prometheus prometheus-community/prometheus --version 15.0.2

# Setup EFK-stack (elasticsearch, fluent-bit, and kibana)
# helm install --name elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=pline --wait
# helm test elk --cleanup

helm repo add elastic https://helm.elastic.co
helm install fawkes-eck-operator elastic/eck-operator --version 1.9.1

# # Delight
# TODO: mssheldon - 05/02/2019; logging is way too high for some reason.  Circle back on this later.
# helm install --namespace=pline stable/anchore-engine --name anchore --wait

#JMETER
# helm install --namespace=pline --name jmeter stable/distributed-jmeter --wait

helm repo add cloudnativeapp https://cloudnativeapp.github.io/charts/curated/
helm install fawkes-distributed-jmeter cloudnativeapp/distributed-jmeter --version 1.0.1

#NEXUS IQ
# kubectl apply --namespace=pline  -f nexusiq/iq-server-all.yaml 

#HYGIEIA
# cd hygieia
# ./hygieia-reinstall.sh
# cd ..

# helm install --namespace=pline stable/ --name 

# GITLAB
# helm install --namespace=pline stable/ --name 
# helm repo add gitlab http://charts.gitlab.io/
# helm install fawkes-gitlab gitlab/gitlab --version 5.6.2

#ECLIPSE CHE
# helm install --namespace=pline stable/ --name 
 helm repo add eclipse-che https://eclipse-che.github.io/che-operator/charts
 helm install fawkes-eclipse-che eclipse-che/eclipse-che --version 7.41.2

