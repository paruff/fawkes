# Helm 
# # kubectl apply -f tiller-user.yaml
# kubectl -n kube-system create serviceaccount tiller
# kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# helm init --service-account tiller --history-max 200
 helm init --tiller-tls-verify --history-max 200
# --tiller-tls-verify
# kubectl rollout status -h
# kubectl rollout status deployment tiller-deploy -n kube-system

helm install --wait stable/kubernetes-dashboard --name dashboard-demo

kubectl create namespace pipeline

# Helm up basic
# # Jenkins
  kubectl apply -f jenkins/service-account.yaml
  helm install --namespace=pipeline stable/jenkins --name jenkins -f jenkins/values.yaml --wait 
echo "Jenkins admin password:"
printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
export JENKINS_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")

echo "Jenkins LB URL"http://$JENKINS_IP:8080/login
# printf $(kubectl get secret --namespace pipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 
# export JENKINS_SERVICE_IP=$(kubectl get svc --namespace pipeline jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
#  echo http://$SERVICE_IP:8080/login

# # Sonarqube
helm install --name sonarqube stable/sonarqube -f sonarqube/sonarqube-values.yaml --namespace=pipeline --wait
helm test sonarqube --cleanup
# get latest load balancer path to sonarqube chart
export SERVICE_IP=$(kubectl get svc --namespace pipeline sonarqube-sonarqube --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP:9000

helm install --namespace=pipeline stable/sonatype-nexus --name registry --set nexus.service.type=LoadBalancer --wait
## where is the url? change nexus.service.type to loadbalancer --set nexus.service.type=LoadBalancer
## uid: admin, pw: admin123
## I don't seem to have access externally

helm install --namespace=pipeline stable/selenium --name selenium --set chromeDebug.enabled=true --set .enabled=true --wait
## internal URL - http://selenium-selenium-hub.pipeline:4444

helm install --namespace=pipeline stable/spinnaker --name spinnaker --wait

# # Satisfied
kubectl create secret generic --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=prometheus/additional-scrape-configs.yaml
helm install --name prometheus --namespace pipeline -f prometheus/prometheus-values.yaml stable/prometheus-operator --wait

# Setup EFK-stack (elasticsearch, fluent-bit, and kibana)
helm install --name elk stable/elastic-stack -f elk-stack/elk-values.yaml --namespace=pipeline --wait
helm test elk --cleanup

# # Delight
# TODO: mssheldon - 05/02/2019; logging is way too high for some reason.  Circle back on this later.
# helm install --namespace=pipeline stable/anchore-engine --name anchore --wait

helm install --namespace=pipeline --name jmeter stable/distributed-jmeter --wait

cd hygieia
./hygieia-reinstall.sh
cd ..

# helm install --namespace=pipeline stable/ --name 
