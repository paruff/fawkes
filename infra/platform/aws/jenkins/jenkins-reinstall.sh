#!/usr/bin/env bash
# jenkins-reinstall.sh
## Use to update Jenkins with new configurations (from values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

helm ls --all jenkins
helm del jenkins
helm del --purge jenkins
kubectl delete pvc -l release=jenkins,component=data

kubectl apply -f service-account.yaml
helm install --namespace=pipeline stable/jenkins --name jenkins -f values.yaml --wait

echo "Jenkins admin password:"
printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
export JENKINS_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Jenkins LB URL"http://$JENKINS_IP:8080/login