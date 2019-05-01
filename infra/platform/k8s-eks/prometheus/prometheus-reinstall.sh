#!/usr/bin/env bash
# prometheus-reinstall.sh
## Use to update Prometheus with new configurations (from prometheus-values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

# BEGIN Cleanup
for n in $(kubectl get namespaces -o jsonpath={..metadata.name}); do
  kubectl delete --all --namespace=pipeline prometheus,servicemonitor,alertmanager
done

sleep 20

kubectl delete -f bundle.yaml

for n in $(kubectl get namespaces -o jsonpath={..metadata.name}); do
  kubectl delete --ignore-not-found --namespace=pipeline service prometheus-operated alertmanager-operated
done

kubectl delete --ignore-not-found customresourcedefinitions \
  prometheuses.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com

# catch all in case part of the release remains
helm del --purge prometheus
kubectl delete pvc -l release=prometheus,component=data

sleep 20
# END Cleanup

kubectl create secret generic --namespace pipeline additional-scrape-configs --from-file=prometheus-additional.yaml --dry-run -oyaml > additional-scrape-configs.yaml
helm install --name prometheus --namespace pipeline -f prometheus-values.yaml stable/prometheus-operator
# helm install --namespace=pipeline -f prometheus-values.yaml stable/prometheus --name prometheus --wait

# kubectl get crd
# kubectl get pods -n pipeline
# kubectl get po -o wide -n=pipeline

# Alert manager port-forward example
# kubectl port-forward -n pipeline alertmanager-prometheus-prometheus-oper-alertmanager-0 9093
# kubectl port-forward -n pipeline svc/alertmanager-operated 9093:9093

# Prometheus server port-forward example
# kubectl port-forward -n pipeline prometheus-prometheus-prometheus-oper-prometheus-0 9090
# kubectl port-forward -n pipeline svc/prometheus-prometheus-oper-prometheus 9090:9090