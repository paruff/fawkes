#!/usr/bin/env bash
# prometheus-reinstall.sh
## Use to update Prometheus with new configurations (from prometheus-values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

helm ls --all prom
helm del prom
helm del --purge prom
kubectl delete pvc -l release=prom,component=data

helm install --name prom --namespace pipeline -f prometheus-values.yaml  stable/prometheus-operator

kubectl get crd
kubectl get pods -n pipeline

# Alert manager
kubectl port-forward -n pipeline alertmanager-prom-prometheus-operator-alertmanager-0 9093
kubectl port-forward -n pipeline prometheus-alertmanager-7f67c49686-qvx4z 9093

# Prometheus server
kubectl port-forward -n pipeline prometheus-prom-prometheus-operator-prometheus-0 9090
kubectl port-forward -n pipeline prometheus-server-75679ccf4f-7fr6c 9090