#!/usr/bin/env bash
# prometheus-reinstall.sh
# Use to update Prometheus with new configurations (from prometheus-values.yaml)
# Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

set -euo pipefail

# BEGIN Cleanup
for _ in $(kubectl get namespaces -o jsonpath="{..metadata.name}"); do
  kubectl delete --all --namespace=pipeline prometheus,servicemonitor,alertmanager
done

sleep 20

kubectl delete -f bundle.yaml

for _ in $(kubectl get namespaces -o jsonpath="{..metadata.name}"); do
  kubectl delete --ignore-not-found --namespace=pipeline service prometheus-operated alertmanager-operated
done

kubectl delete --ignore-not-found customresourcedefinitions \
  prometheuses.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com

kubectl delete secret --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg

# catch all in case part of the release remains
helm del --purge prometheus
kubectl delete pvc -l release=prometheus,component=data

sleep 20
# END Cleanup

# dry-run only
# kubectl create secret generic --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=additional-scrape-configs.yaml --dry-run -oyaml > additional-scrape-configs-secret.yaml

kubectl create secret generic --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=additional-scrape-configs.yaml
helm install --name prometheus --namespace pipeline -f prometheus-values.yaml stable/prometheus-operator --wait

# login (default: admin/prom-operator)
echo "prometheus-grafana admin password:"
printf "%s" "$(kubectl get secret --namespace pipeline prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)"
echo

# echo "additional-scrape-configs:"
# printf "%s" "$(kubectl get secret --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg -o jsonpath="{.data.*}" | base64 --decode)"
# echo