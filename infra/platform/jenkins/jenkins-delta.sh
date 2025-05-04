#!/usr/bin/env bash
set -x
# jenkins-reinstall.sh
## Use to update Jenkins with new configurations (from values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough

helpFunction() {
   echo ""
   echo "Usage: $0 -i  - parameterB -c parameterC"
   echo -e "\t-i install"
   echo -e "\t-s show"
   echo -e "\t-t test"
   echo -e "\t-u uninstall"
   exit 1 # Exit script after printing help
}

install() {
   echo "installing"
   helm install fawkes-jenkins jenkinsci/jenkins -f values.yaml --wait
   exit
}

reinstall() { 
   uninstall
   install
}

show() {
   helm show "$SERVICE"
}

test() {
    echo "testing"
    helm test fawkes-jenkins 
}

uninstall() { 
    echo "uninstall $SERVICE"
    helm ls --all jenkins
    helm del jenkins
    helm del --purge jenkins
    kubectl delete pvc -l release=jenkins,component=data
}

SERVICE=jenkins

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install)
      install
      ;;
    -s|--show)
      show
      ;;
    -t|--test)
      test
      ;;
    -r|--reinstall)
      reinstall
      ;;
    -u|--uninstall)
      uninstall
      ;;
    --default)
      # DEFAULT=YES # (Unused, so removed)
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

# Example admin password and Jenkins URL output
echo "Jenkins admin password:"
printf "%s" "$(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)"
echo

JENKINS_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
export JENKINS_IP

echo "Jenkins LB URL: http://$JENKINS_IP:8080/login"