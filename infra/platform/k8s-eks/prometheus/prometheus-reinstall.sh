#!/usr/bin/env bash
# prometheus-reinstall.sh
## Use to update Prometheus with new configurations (from prometheus-values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

# BEGIN Cleanup
for n in $(kubectl get namespaces -o jsonpath={..metadata.name}); do
  kubectl delete --all --namespace=pipeline prometheus,servicemonitor,alertmanager
done

sleep 120

kubectl delete -f bundle.yaml

for n in $(kubectl get namespaces -o jsonpath={..metadata.name}); do
  kubectl delete --ignore-not-found --namespace=pipeline service prometheus-operated alertmanager-operated
done

kubectl delete --ignore-not-found customresourcedefinitions \
  prometheuses.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com
# END Cleanup

kubectl create secret generic additional-scrape-configs --from-file=prometheus-additional.yaml --dry-run -oyaml > additional-scrape-configs.yaml
helm install --name prometheus --namespace pipeline -f prometheus-values.yaml stable/prometheus-operator
# helm install --namespace=pipeline -f prometheus-values.yaml stable/prometheus --name prometheus --wait

kubectl get crd
kubectl get pods -n pipeline

# Alert manager port-forward example
# kubectl port-forward -n pipeline prometheus-alertmanager-7f67c49686-qvx4z 9093

# Prometheus server port-forward example
# kubectl port-forward -n pipeline prometheus-server-75679ccf4f-7fr6c 9090