#!/usr/bin/env bash
# buildinfra.sh
## TODO
# break up cloud provider terraform k8s up

# IAC a vpc and k8s cluster 
terraform init
terraform fmt
terraform plan
terraform apply --auto-approve

# set the kubetnetes config info 
# aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

# Configure kubectl Config
# can't find the cluster_name :-()
# aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

mkdir -p $HOME/.kube
cp kubeconfig_* $HOME/.kube/config
cp kubeconfig_* $HOME/.kube/
export  KUBECONFIG_SAVED=$KUBECONFIG
export KUBECONFIG=$HOME/.kube/config

# move to localk8s config
# mkdir -p /tmp
# terraform output config_map_aws_auth > /tmp/configmap.yml
# kubectl apply -f /tmp/configmap.yml

# Create namespaces for fawkes and envs 

kubectl create namespace fawkes
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod

sleep 5
