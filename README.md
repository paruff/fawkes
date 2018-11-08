# starter-project

| service  |  repo |  regisrty | port  | endpoint  |
|---|---|---|---|---|
|  myuscis_tip_svc | https://github.com/Unisys/myuscis-tip-svc/  | https://hub.docker.com/r/paruff/myuscis-tip-svc/  | 80  | ???  |
|  case | unisys/myuscis-case-svc  | paruff/myuscis-case-svc  | 8080  |  ??? |
| sec-tips  | unisys/myuscis-sec-tips-svc  | paruff/myuscis-sec-tips-svc  | 8081  | ???  |


## project envs
| env | url |
|---|---|
|dev|http://verfut-de-External-1NUDTVSK6RMML-577586660.us-east-1.elb.amazonaws.com/|
|automated test|http://verfut-at-External-1BFOJZVDQL4A2-1863726564.us-east-1.elb.amazonaws.com/|

## Pipeline/platform resources
| Service | url |
|---|---|
| Jenkins | http://ec2-18-212-234-148.compute-1.amazonaws.com/|
| sonar |  http://platform-externall-ozafy5g1zflk-1223084853.us-east-1.elb.amazonaws.com:9000/|
| nexus|  http://platform-externall-ozafy5g1zflk-1223084853.us-east-1.elb.amazonaws.com:8081/
|prometheus|http://platform-externall-ozafy5g1zflk-1223084853.us-east-1.elb.amazonaws.com:9090/|
|selenium hub|http://platform-externall-ozafy5g1zflk-1223084853.us-east-1.elb.amazonaws.com:3000/|
|visualizer|http://platform-externall-ozafy5g1zflk-1223084853.us-east-1.elb.amazonaws.com:8079/|


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
