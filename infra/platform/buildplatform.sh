#!/usr/bin/env bash
# infra-k8s-boot.sh
## TODO
# conditional helm install and update based on does it exist

helm repo add k8s-dashboard https://kubernetes.github.io/dashboard
helm install fawkes-k8s-dashboard k8s-dashboard/kubernetes-dashboard --version 5.0.5
helm test fawkes-k8s-dashboard
# helm install --wait stable/kubernetes-dashboard --name dashboard-demo

# Helm up basic
# # Jenkins
helm repo add jenkinsci https://charts.jenkins.io/
helm install fawkes-jenkins jenkinsci/jenkins --values jenkins/values.yaml
helm test fawkes-jenkins 
# change to LTS version
# add plugins for different pipelines


# kubectl apply -f jenkins/service-account.yaml
# helm install --namespace=fawkes stable/jenkins --name jenkins -f jenkins/values.yaml --wait 
# echo "Jenkins admin password:"
# printf $(kubectl get secret --namespace fawkes jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# export JENKINS_IP=$(kubectl get svc --namespace fawkes jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

# echo "Jenkins LB URL"http://$JENKINS_IP:8080/login
# printf $(kubectl get secret --namespace fawkes jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace fawkes jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login

# # Sonarqube
# helm install --name sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=fawkes --wait
# helm test sonarqube --cleanup
# get latest load balancer path to sonarqube chart
# export SERVICE_IP=$(kubectl get svc --namespace fawkes sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
# echo http://$SERVICE_IP:9000

helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm upgrade --install sonarqube sonarqube/sonarqube-lts
helm test sonarqube


helm repo add harbor https://helm.goharbor.io
helm install my-harbor harbor/harbor --version 1.8.1


helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-keycloak bitnami/keycloak --version 6.0.0


# helm install --namespace=fawkes stable/docker-registry  --name registry --wait 
# helm install --namespace=fawkes stable/sonatype-nexus --name registry --set nexus.service.type=LoadBalancer --wait
## uid: admin, pw: admin123
## I don't seem to have access externally

#SELENIUM 
helm repo add douban https://douban.github.io/charts/
helm install fawkes-selenium douban/selenium --version 1.3.0
helm test fawkes-selenium 
# helm install --namespace=fawkes stable/selenium --name selenium --set chromeDebug.enabled=true --set .enabled=true --wait
## internal URL - http://selenium-selenium-hub.fawkes:4444

# spinnaker
# helm install --namespace=fawkes stable/spinnaker --name spinnaker --wait

helm repo add opsmx https://helmcharts.opsmx.com/
helm install fawkes-spinnaker opsmx/spinnaker --version 2.2.7
helm test fawkes-spinnker

# # Satisfied
#PROMETHEUS
#  kubectl create secret generic --namespace fawkes prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
# helm install --name prometheus --namespace fawkes -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install fawkes-prometheus prometheus-community/prometheus --version 15.0.2
helm test fawkes-prometheus

# Setup EFK-stack (elasticsearch, fluent-bit, and kibana)
# helm install --name elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=fawkes --wait
# helm test elk --cleanup

helm repo add elastic https://helm.elastic.co
helm install fawkes-eck-operator elastic/eck-operator --version 1.9.1
helm test fawkes-eck-operator

# # Delight
# TODO: logging is way too high for some reason.  Circle back on this later.
helm repo add anchore-charts https://charts.anchore.io
helm install my-anchore-engine anchore-charts/anchore-engine --version 1.16.0
helm test fawkes-anchore-engine 
# helm install --namespace=fawkes stable/anchore-engine --name anchore --wait

#JMETER
# helm install --namespace=fawkes --name jmeter stable/distributed-jmeter --wait

helm repo add cloudnativeapp https://cloudnativeapp.github.io/charts/curated/
helm install fawkes-distributed-jmeter cloudnativeapp/distributed-jmeter --version 1.0.1
helm test fawkes-distributed-jmeter

#NEXUS IQ
# kubectl apply --namespace=fawkes  -f nexusiq/iq-server-all.yaml 

#HYGIEIA
# cd hygieia
# ./hygieia-reinstall.sh
# cd ..

# helm install --namespace=fawkes stable/ --name 

# GITLAB
# helm install --namespace=fawkes stable/ --name 
# helm repo add gitlab http://charts.gitlab.io/
# helm install fawkes-gitlab gitlab/gitlab --version 5.6.2

#ECLIPSE CHE
# helm install --namespace=fawkes stable/ --name 
# helm repo add eclipse-che https://eclipse-che.github.io/che-operator/charts
# helm install fawkes-eclipse-che eclipse-che/eclipse-che --version 7.41.2

