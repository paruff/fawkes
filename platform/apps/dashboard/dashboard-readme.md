To enable a Dashboard follow these instructions:

1. https://github.com/kubernetes/dashboard
2. https://github.com/kubernetes/dashboard/wiki/Creating-sample-user

dashboard-adminuser.yaml is provided in this directory

to get bearer token for login:

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

remember to run 'kubectl proxy' before trying to navigate to the dashboard at:

http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
