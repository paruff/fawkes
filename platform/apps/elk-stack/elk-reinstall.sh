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

# kubectl get svc -n=pipeline

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

# connect to a pod via bash
# kubectl get pods --namespace pipeline
# kubectl -n pipeline exec -it ##POD_NAME## bash

# check logs
# kubectl logs elk-fluent-bit-##POD_NAME## --namespace pipeline

#######################################################
# ALTERNATE APPROACH 1 IF ABOVE CHART PROVES TOO BUGGY
# Downside, dependency on one person's custom chart
# and no apparent versioning.
# The author does claim to release via official
# sites periodically -- see: https://kubeapps.com/
#######################################################

# helm ls --all efk
# helm del efk
# helm del --purge efk
# kubectl delete pvc -l release=efk,component=data

# helm repo add akomljen-charts https://raw.githubusercontent.com/komljen/helm-charts/master/charts/
# helm install --name es-operator --namespace pipeline akomljen-charts/elasticsearch-operator
# kubectl get pods -n pipeline
# kubectl get CustomResourceDefinition
# kubectl describe CustomResourceDefinition elasticsearchclusters.enterprises.upmc.com
# helm install --name efk --namespace pipeline akomljen-charts/efk --wait
# helm test efk --cleanup
# kubectl get cronjob -n pipeline

# kubectl get pods -n pipeline
# kubectl port-forward efk-kibana-##REPLACE## 5601 -n pipeline

######################################################
# ALTERNATE APPROACH 2
######################################################
# https://www.elastic.co/blog/alpha-helm-charts-for-elasticsearch-kibana-and-cncf-membership
# helm repo add elastic https://helm.elastic.co
# helm install --name elasticsearch elastic/elasticsearch --namespace=pipeline
# helm install --name kibana elastic/kibana --namespace=pipeline
# then install fluentd or flient-bit