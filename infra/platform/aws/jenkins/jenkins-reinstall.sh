#!/usr/bin/env bash -x
# jenkins-reinstall.sh
## Use to update Jenkins with new configurations (from values.yaml)
## Note: sometimes it is necessary to rerun/retry this script multiple times as some resources may not get deleted quickly enough
SERVICE=jenkins

helpFunction()
{
   echo ""
   echo "Usage: $0 -i  - parameterB -c parameterC"
   echo -e "\t-i install"
   echo -e "\t-s show "
   echo -e "\t-t test"
   echo -e "\t-u uninstall"
   exit 1 # Exit script after printing help
}

install()
{
   echo "installing "
   helm install fawkes-jenkins jenkinsci/jenkins   -f values.yaml --wait
   exit
}

reinstall()
{ 
uninstall
install
}

show() {
 helm show $service
}

test()
{
    echo "testing"
    helm test fawkes-jenkins 
}

uninstall()
{ 
echo " uninstall $service"
helm ls --all jenkins
helm del jenkins
helm del --purge jenkins
kubectl delete pvc -l release=jenkins,component=data
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--install)
      install    ;;
    -s|--show)
      show    ;;
    -t|--test)
      test    ;;
    -r|--reinstall)
      reinstall    ;;
    -u|--uninstall)
      uninstall    ;;
    --default)
      DEFAULT=YES
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


# Print helpFunction in case parameters are empty
if [ -z "$parameterA" ] || [ -z "$parameterB" ] || [ -z "$parameterC" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script in case all parameters are correct
echo "$parameterA"
echo "$parameterB"
echo "$parameterC"




helm ls --all jenkins
helm del jenkins
helm del --purge jenkins
kubectl delete pvc -l release=jenkins,component=data

helm install --namespace=pipeline stable/jenkins --name jenkins -f values.yaml --wait

echo "Jenkins admin password:"
printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
export JENKINS_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Jenkins LB URL"http://$JENKINS_IP:8080/login