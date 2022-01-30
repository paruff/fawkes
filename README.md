# Fawkes is a open source project to stand up a work space and a k8s based continuous integration and continuos delivery pipeline

<<<<<<< HEAD
| service  |  repo |  regisrty | port  | endpoint  |
|---|---|---|---|---|
|  ui | https://gitlab.com/Unisys/-tip-ui/  | https://hub.docker.com/r/paruff/myuscis-tip-svc/  | 80  | ???  |
|  svc1 | unisys/svc1  | paruff/svc1  | 8080  |  ??? |
|  svc2 | unisys/svc2  | paruff/svc2  | 8081  | ???  |
=======
Workspace is supports windows and mac os useing choco and brew.
>>>>>>> develop

It is currently built on aws and uses terraform to build the k8s cluster so a todo is add azure, google cloud etc.

<<<<<<< HEAD
## project envs
| env | url |
|---|---|
|dev|http://??/|
|automated test|http://???/|

## Pipeline/platform resources
| Service | url |
|---|---|
| Jenkins | http://ac31c3d2a5d3711e985de0ebf3e1312a-2067130682.us-east-1.elb.amazonaws.com:8080/|
| sonar |  http://a116e8fb55d3811e985de0ebf3e1312a-120804566.us-east-1.elb.amazonaws.com:9000/|
| nexus|  http://platform-externall-ozafy5g1zflk-1223084853.us-east-1.elb.amazonaws.com:8081/
|selenium hub|http://a4af0c9005d3811e985de0ebf3e1312a-2036822307.us-east-1.elb.amazonaws.com:4444/|


## to add a new service:
1 create a new github account
2 select setting -> collaboration & teams -> provide admin to uscis-myuscis
3 select settings -> Webhooks -> Add Webhook
4 enter http://ec2-35-153-213-248.compute-1.amazonaws.com:8080/github-webhook/ 
5 choose json
6 select Add Webhook
7 add line to above table
8 enter service name, repo, endpoints


## Platform(phil)   
1 add docker hub repo
2 add Jenkinsfile
3 add Jenkins job
4 add service and port to docker-compose.yml
5 
=======
Also there are supporting project templates as starters for project teams that want to start deliverying microservice into k8s in a clone and few edits. The first versions of this were java sprnt boot based and other container based languages and framwworks are other todos for templates.

Fawkes is named aft Dumbledores phoenix who in turn was named after [Guy Fawkes](https://en.wikipedia.org/wiki/Guy_Fawkes) from british history.
>>>>>>> develop
