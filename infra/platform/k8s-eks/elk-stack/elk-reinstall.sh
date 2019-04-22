#!/usr/bin/env bash
# elk-reinstall.sh
## Use to update ELK with new configurations (from elk-values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

helm ls --all elk
helm del elk
helm del --purge elk
kubectl delete pvc -l release=elk,component=data
# todo: need to wait here until terminate is complete

helm install --name elk stable/elastic-stack -f elk-values.yaml --namespace=pipeline --wait
helm test elk --cleanup

# kubectl get nodes
# kubectl get po -o wide -n=pipeline
# kubectl get svc -w elk-kibana --namespace pipeline

kubectl get svc -n=pipeline

export POD_NAME=$(kubectl get pods --namespace pipeline -l "app=kibana,release=elk" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:5601 to use Kibana"
kubectl port-forward --namespace pipeline $POD_NAME 5601:5601
