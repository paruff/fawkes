#!/usr/bin/env bash

# Imperative install/reinstall of Hygieia

# Note: resource requirements for these deployments come in at about 4Gb
# For minikube deployments be sure to configure enough memory.  At minimum do:
# 'minikube config set memory 4096' (after minikube stop and minikube delete as needed)
# you can always check utilization with 'kubectl describe nodes -n pipeline'

# BEGIN Cleanup

kubectl --namespace pipeline delete deployment sonar-codequality-collector

#  ideally should remove collectors from mongo unless completely starting over
# example: db.collectors.remove({"_id": ObjectId("4d512b45cc9374271b02ec4f")})
kubectl --namespace pipeline delete deployment jira-collector

kubectl --namespace pipeline delete deployment gitlab-feature-collector
kubectl --namespace pipeline delete deployment gitlab-scm-collector
# kubectl --namespace pipeline delete deployment jenkins-cucumber-test-collector
# kubectl --namespace pipeline delete deployment jenkins-codequality-collector
kubectl --namespace pipeline delete deployment jenkins-build-collector

kubectl --namespace pipeline delete svc ui
kubectl --namespace pipeline delete deployment ui

kubectl --namespace pipeline delete svc api
kubectl --namespace pipeline delete deployment api

kubectl --namespace pipeline delete svc db
kubectl --namespace pipeline delete deployment db

kubectl --namespace pipeline delete configmap mongo-initdb
kubectl --namespace pipeline delete pvc db-data

sleep 20

# END Cleanup

# TODO: remove this line when calling this script from infra-k8s-boot.sh
kubectl create namespace pipeline

kubectl create --namespace pipeline -f db-data-persistentvolumeclaim.yaml

kubectl create --namespace pipeline configmap mongo-initdb --from-file=createuser.sh

kubectl create --namespace pipeline -f db-deployment.yaml
# kubectl --namespace pipeline logs -f deploy/db
# connect to a pod via bash
# kubectl get pods --namespace pipeline
# kubectl -n pipeline exec -it ##POD_NAME## bash

kubectl create --namespace pipeline -f db-service.yaml
# kubectl port-forward --namespace pipeline svc/db 27017:27017

# wait a bit here until mongo is up and initial user is created
sleep 30

# todo: use LDAP auth. see: https://github.com/Hygieia/Hygieia/issues/1984
kubectl create --namespace pipeline -f api-deployment.yaml
# kubectl --namespace pipeline logs -f deploy/api
kubectl create --namespace pipeline -f api-service.yaml

# wait a bit here until initial mongo collections are created by the API
sleep 30

kubectl create --namespace pipeline -f ui-deployment.yaml
# kubectl --namespace pipeline logs -f deploy/ui
kubectl create --namespace pipeline -f ui-service.yaml
# kubectl port-forward --namespace pipeline svc/ui 3000:3000

# Add Collectors
# requires an api token in place of password for REST calls
#  obtained by:  echo -n michael.sheldon@unisys.com:THETOKENCREATEDONUSERPROFILE | base64
kubectl create --namespace pipeline -f jira-collector-deployment.yaml

kubectl create --namespace pipeline -f jenkins-build-collector-deployment.yaml
# kubectl create --namespace pipeline -f jenkins-codequality-collector-deployment.yaml
# kubectl create --namespace pipeline -f jenkins-cucumber-test-collector-deployment.yaml
kubectl create --namespace pipeline -f gitlab-scm-collector-deployment.yaml
kubectl create --namespace pipeline -f gitlab-feature-collector-deployment.yaml

kubectl create --namespace pipeline -f sonar-codequality-collector-deployment.yaml