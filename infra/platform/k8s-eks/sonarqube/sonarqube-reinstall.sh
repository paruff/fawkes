#!/usr/bin/env bash
# sonarqube-reinstall.sh
## Use to update Sonarqube with new configurations (from sonarqube-values.yaml)

helm del sonarqube
helm del --purge sonarqube
helm install --name sonarqube stable/sonarqube -f sonarqube-values.yaml --namespace=pipeline --wait ; helm test sonarqube

kubectl get svc -n=pipeline

# get latest load balancer path to sonarqube chart
export SERVICE_IP=$(kubectl get svc --namespace pipeline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP:9000
