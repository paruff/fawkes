#!/usr/bin/env bash
# elk-reinstall.sh
## Use to update ELK with new configurations (from elk-values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

helm ls --all elk
helm del elk
helm del --purge elk
kubectl delete pvc -l release=elk,component=data
# todo: need to wait here until terminate is complete

helm install --name elk stable/elastic-stack --version 1.6.0 -f elk-values.yaml --namespace=pipeline --wait

# if tests hang or do not cleanup you can delete pods manually as follows:
# kubectl get pods --namespace pipeline
# kubectl --namespace pipeline delete pods elk-ui-test-VARIABLEPARTFROMLISTABOVE
helm test elk --cleanup

# kubectl get nodes
# kubectl get po -o wide -n=pipeline
# kubectl get svc -w elk-kibana --namespace pipeline

kubectl get svc -n=pipeline

# Kibana port forwarding
# export POD_NAME=$(kubectl get pods --namespace pipeline -l "app=kibana,release=elk" -o jsonpath="{.items[0].metadata.name}")
# echo "Visit http://127.0.0.1:5601 to use Kibana"
# kubectl port-forward --namespace pipeline $POD_NAME 5601:5601

# elasticsearch client port forwarding
# export ES_POD_NAME=$(kubectl get pods --namespace pipeline -l "app=elasticsearch,release=elk" -o jsonpath="{.items[0].metadata.name}")
# echo "Visit http://127.0.0.1:9200 to use elasticsearch client"
# kubectl port-forward --namespace pipeline $ES_POD_NAME 9200:9200
# Now you can use curl.  Here are some examples:
# curl -XGET 'http://localhost:9200/_count?pretty' -d '{"query": {"match_all": {}}}' -H 'Content-Type: application/json'
