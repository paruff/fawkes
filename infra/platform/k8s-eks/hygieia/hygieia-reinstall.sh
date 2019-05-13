#!/usr/bin/env bash

# Imperative install/reinstall of Hygieia

# BEGIN Cleanup
kubectl delete svc db
kubectl delete deployment db
kubectl delete configmap mongo-initdb
kubectl delete pvc db-data

sleep 20

# END Cleanup

kubectl create -f db-data-persistentvolumeclaim.yaml

kubectl create configmap mongo-initdb --from-file=createuser.sh

kubectl create -f db-deployment.yaml
# kubectl logs -f deploy/db
# connect to a pod via bash
# kubectl get pods --namespace pipeline (or leave off namespace when working with minikube)
# kubectl -n pipeline exec -it ##POD_NAME## bash

kubectl create -f db-service.yaml
# kubectl port-forward svc/db 27017:27017

# TODO: may need to wait a bit here until mongo is up and initial user is created

kubectl create -f api-deployment.yaml
# kubectl logs -f deploy/api
kubectl create -f api-service.yaml

kubectl create -f ui-deployment.yaml
# kubectl logs -f deploy/ui
kubectl create -f ui-service.yaml
