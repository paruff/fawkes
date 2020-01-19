#!/usr/bin/env bash
# .sh
## TODO
# conditional helm install and update based on does it exist
# break up cloud provider terraform k8s up
# os or shell conditional installs of packages mac, win , yum, apt-get?
# #{{{ Bash settings
# # abort on nonzero exitstatus
# set -o errexit
# # abort on unbound variable
# set -o nounset
# # don't hide errors within pipes
# set -o pipefail
# #}}}
# #{{{ Variables
# readonly script_name=$(basename "${0}")
# readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# IFS=$'\t\n'   # Split on newlines and tabs (but not on spaces)

#}}}

sub_command=$@

# Set Terraform State Paths
#tf_dir=${tf_dir:=tfstate/latest}
#tf_state=$tf_dir/terraform.tfstate

# Control Debug logs
boot_debug=${boot_debug:=0}

environments='dev test prod'
jenkins_values_file=ignore/jenkins_values_final.yaml


init() {
  [ -d .terraform ] || terraform init

  # prepare state
 # mkdir -p $tf_dir
 # [ -f $tf_dir/vars.tfvars ] || cp vars.tfvars $tf_dir

  # make sure there is an ignore directory
  mkdir -p ignore
}

plan() {
  init

  debug "Running plan"

#  terraform plan -var-file=$tf_dir/vars.tfvars -state=$tf_state

  terraform plan 
}

deploy() {
  prepspace
  plan

  echo "Deploying AWS Resources using Terraform"

  deploy_cloud_resources

  deploy_k8s_resources

  show
}

deploy_cloud_resources(){
provision_cloud
} 


deploy_k8s_resources(){
  install_foundations
  install_satisfy
  install_delight
} 

install_foundations(){
  install_jenkins
  install_dashboard
  install_sonarqube
  install_selenium
}

install_satisfy(){
    install_elk
    install_prometheus
    install_hygieia
}
install_delight(){
    install_anchore
    install_nexusiq
}


show() {
  export JENKINS_ADMIN_USER="admin"
  export JENKINS_ADMIN_PASSWORD=$(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)
  export JENKINS_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export JENKINS_LB_URL="http://$JENKINS_IP"

  # get latest load balancer path to sonarqube chart
  export SONARQUBE_SERVICE_IP=$(kubectl get svc --namespace pipeline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export SONARQUBE_LB_URL="http://$SONARQUBE_SERVICE_IP:9000"

  token_name=$(kubectl -n kube-system get secret -o custom-columns=NAME:.metadata.name | grep dashboard-admin-user-token)
  export DASHBOARD_ADMIN_TOKEN=$(kubectl -n kube-system get secret $token_name -o jsonpath='{.data.token}' | base64 --decode)
  export DASHBOARD_SERVICE_IP=$(kubectl get svc --namespace kube-system kubernetes-dashboard --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  export DASHBOARD_LB_URL="https://$DASHBOARD_SERVICE_IP"

  #Keycloak

#   export DEV_KEYCLOAK_URL=$(kubectl get svc --namespace dev dev-keycloak-http -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#   export DEV_KEYCLOAK_PASS=$(kubectl get secret --namespace dev dev-keycloak-http -o jsonpath="{.data.password}" | base64 --decode)

#   export TEST_KEYCLOAK_URL=$(kubectl get svc --namespace test test-keycloak-http -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#   export TEST_KEYCLOAK_PASS=$(kubectl get secret --namespace test test-keycloak-http -o jsonpath="{.data.password}" | base64 --decode)

#   export PROD_KEYCLOAK_URL=$(kubectl get svc --namespace prod prod-keycloak-http -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#   export PROD_KEYCLOAK_PASS=$(kubectl get secret --namespace prod prod-keycloak-http -o jsonpath="{.data.password}" | base64 --decode)

  #kubectl get secret --namespace prod prod-keycloak-http -o jsonpath="{.data.password}" | base64 --decode; echo

  echo
  echo "Setup Script Outputs:"
  echo "=========================================================="
  echo
  echo "Jenkins admin user:       $JENKINS_ADMIN_USER"
  echo "Jenkins admin password:   $JENKINS_ADMIN_PASSWORD"
  echo "Jenkins LB URL            $JENKINS_LB_URL"
  echo
  echo "Sonarqube LB URL:         $SONARQUBE_LB_URL"
  echo "Sonarqube admin user:     admin"
  echo "Sonarqube admin password: admin"
  echo
  echo "Kubernetes Dashboard LB URL:         $DASHBOARD_LB_URL"
  echo "Kubernetes Dashboard admin token:    $DASHBOARD_ADMIN_TOKEN"
  #echo "Kubernetes Dashboard readonly token: "
#   echo
#   echo "DEV Keycloak LB URL:              $DEV_KEYCLOAK_URL"
#   echo "DEV Keycloak LB admin user:       keycloak"
#   echo "DEV Keycloak LB admin password:   $DEV_KEYCLOAK_PASS"
#   echo
#   echo "TEST Keycloak LB URL:             $TEST_KEYCLOAK_URL"
#   echo "TEST Keycloak LB admin user:      keycloak"
#   echo "TEST Keycloak LB admin password:  $TEST_KEYCLOAK_PASS"
#   echo
#   echo "PROD Keycloak LB URL:             $PROD_KEYCLOAK_URL"
#   echo "PROD Keycloak LB admin user:      keycloak"
#   echo "PROD Keycloak LB admin password:  $PROD_KEYCLOAK_PASS"
}


prepspace (){
case "$OSTYPE" in
#  linux*)   machine=Linux;;
  darwin*)  machine=Mac;; 
  win*)     machine=Windows;;
  msys*)    machine=GBash ;;
#  cygwin*)  machine=Cygwin;;
#  bsd*)     machine=BSD;;
  *)        echo "unknown: $OSTYPE" ;;
esac

echo ${machine}

if [ ${machine} = "Mac" ]; 
then
../../workspace/space-setup-macosx.sh
if ! aws-iam-authenticator -h; then
  brew install aws-iam-authenticator
fi

fi
# now for windows 10 running git bash
# TODO define and lock the versions to working versions 
if [ ${machine} = "GBash" ]; 
then
../../workspace/space-setup-win10.ps1
if ! aws-iam-authenticator -h; then
# this aim-authorize-
# https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
#   Linux: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
#    MacOS: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/darwin/amd64/aws-iam-authenticator
#    Windows: https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/windows/amd64/aws-iam-authenticator.exe
 curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/windows/amd64/aws-iam-authenticator.exe
 openssl sha1 -sha256 aws-iam-authenticator.exe
 chmod +x ./aws-iam-authenticator.exe
 mkdir $HOME/bin && cp ./aws-iam-authenticator.exe $HOME/bin/aws-iam-authenticator.exe && export PATH=$HOME/bin:$PATH
 echo 'export PATH=$HOME/bin:$PATH' >> ~/.bash_profile
fi

fi


}

install_helm(){
    # Helm 

helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
}

install_jenkins(){

    # # Jenkins
# kubectl apply -f jenkins/service-account.yaml
helm install jenkins --namespace=pline stable/jenkins  -f jenkins/values.yaml --wait 
echo "Jenkins admin password:"
printf $(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
export JENKINS_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Jenkins LB URL"http://$JENKINS_IP:8080/login
# printf $(kubectl get secret --namespace pline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace pline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login

}

install_sonarqube(){

# # Sonarqube
helm install sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=pline --wait
helm test sonarqube --cleanup
# get latest load balancer path to sonarqube chart
export SERVICE_IP=$(kubectl get svc --namespace pline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP:9000

}

install_selenium(){

helm install selenium --namespace=pline stable/selenium  --set chromeDebug.enabled=true --set .enabled=true --wait
## internal URL - http://selenium-selenium-hub.pline:4444

}

install_spinnaker(){

helm install spinnaker --namespace=pline stable/spinnaker  --wait

}

install_prometheus(){
kubectl create secret generic --namespace pline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
helm install prometheus --namespace pline -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait

}

install_elk(){
    # Setup EFK-stack (elasticsearch, fluent-bit, and kibana)
helm install elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=pline --wait
helm test elk --cleanup

}

install_nexusiq(){
    kubectl apply --namespace=pline  -f nexusiq/iq-server-all.yaml 
}
install_anchore(){
 helm install anchore --namespace=pline stable/anchore-engine  --wait

}


install_hygieia(){
cd hygieia
./hygieia-reinstall.sh
cd ..
}

install_dashboard(){
    helm install dashboard stable/kubernetes-dashboard 
}
destroy(){
    echo "Running terraform destroy to deleting remaining resources"

  #terraform destroy -auto-approve -state=$tf_state
  terraform destroy -auto-approve
}

provision_cloud(){

terraform init
terraform fmt
terraform plan
terraform apply --auto-approve

# Configure kubectl Configure
mkdir -p $HOME/.kube
# terraform output kubeconfig > ~/.kube/config

cp kubeconfig_* $HOME/.kube/config
cp kubeconfig_* $HOME/.kube/


aws eks update-kubeconfig --name pipeline

# move to localk8s config
# mkdir -p /tmp
# terraform output config_map_aws_auth > /tmp/configmap.yml
# kubectl apply -f /tmp/configmap.yml

export  KUBECONFIG_SAVED=$KUBECONFIG
export KUBECONFIG=$HOME/.kube/config


install_helm

kubectl create namespace pline
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

}
#########################
# The command line help #
#########################
display_help() {
    echo "Usage: $0 [option...] {start|stop|restart}" >&2
    echo
    echo "   -r, --resolution           run with the given resolution WxH"
    echo "   -d, --display              Set on which display to host on "
    echo
    # echo some stuff here for the -a or --add-options 
    exit 1
}

debug() {
  if [[ ! -z $boot_debug ]] && [[ $boot_debug -eq 1 ]]; then
    echo $1
  fi
}

help() {
  declare -F 
}

# execute this thing
$sub_command