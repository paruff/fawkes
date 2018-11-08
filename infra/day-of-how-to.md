# Infra day of how to
## get ssh keys
1. log into the aws console
1. select ec2 service
1. select Key Pairs from teh Resources Dashboard
1. Select "Create Key Pair"
1. Enter "platform-{region}" and click "Create"
1. click "OK" to save the keypair on your machine
1. open a bash terminal


## get access and secret keys
1. log on to the aws console
1. select IAM services
1. select "Users" on the left hand navigation menu
1. select given user
1. select "Security Credentials" tab
1. Under "Access Keys", click "Create access key"
1. Select "Download .csv file"
1. select "Save File" and then click "OK"


## aws configure
1. open a bash terminal window
2. enter "aws configure"
3. Enter at "AWS Access Key ID"
4. Enter at "AWS Secret Access Key"
5. Enter at "Default region name"
6. Enter at "Default output format"
```
$ aws configure
AWS Access Key ID [****************CI6A]:
AWS Secret Access Key [****************8c8U]:
Default region name [us-east-2]:
Default output format [None]:
```
7. Validate by entering "aws s3 ls"

## deploy the CI/CD pipeline
1.  scp -i ~/.ssh/platform-use1.pem infra/platform/docker-compose-swarm.yml docker@54.172.210.245:
1.  ssh  -i ~/.ssh/platform-use1.pem docker@54.172.210.245
1.  docker stack deploy -c docker-compose-swarm.yml  pipeline

## Configure Jenkins
1. log into Jenkins
3. configure Jenkins github id
2. configure Jenkins dockerhub id
2. configure github auth and groups
3. configure slack channel
4. configure smtp server
4. configure jobs organization to pull down unisys/{project}-.*

## Configure SonarQube
1. log into SonarQube
3. configure SonarQube github id
