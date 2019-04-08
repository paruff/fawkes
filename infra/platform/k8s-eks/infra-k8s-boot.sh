# infra-k8s-boot.sh

# this assumes terraform is installed
# this aim-authorize-

#!/usr/bin/env bash

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
kubectl rollout status -h

helm install --wait stable/kubernetes-dashboard --name dashboard-demo


# Helm up basic
# kubectl create namespace pipeline
# # Jenkins
helm install --namespace=pipeline stable/jenkins --name jenkins --wait
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

# helm install --namespace=pipeline stable/spinnaker --name spinnaker
# # Satisfied
helm install --namespace=pipeline stable/prometheus --name prometheus --wait

helm install --namespace=pipeline stable/elastic-stack --name elk --wait

# helm install --namespace=pipeline stable/anchore-engine --name anchore

# helm install --namespace=pipeline stable/ --name 

helm install --namespace=pipeline --name jmeter stable/distributed-jmeter --wait

# # Delight







