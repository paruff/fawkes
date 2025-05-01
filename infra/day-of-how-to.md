# Infra day of how to

## get ssh keys

1. log into the aws console
2. select ec2 service
3. select Key Pairs from teh Resources Dashboard
4. Select "Create Key Pair"
5. Enter "platform-{region}" and click "Create"
6. click "OK" to save the keypair on your machine
7. open a bash terminal

## get access and secret keys

1. log on to the aws console
2. select IAM services
3. select "Users" on the left hand navigation menu
4. select given user
5. select "Security Credentials" tab
6. Under "Access Keys", click "Create access key"
7. Select "Download .csv file"
8. select "Save File" and then click "OK"

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
8. Create a profile called terraform (in ~/.aws/credentials) and copy in aws_access_key_id and aws_secret_access_key that you want to use
9. Update ~/.aws/config and set region for terraform profile
10. Export default aws profile
    linux: export AWS_DEFAULT_PROFILE=terraform
    windows: setx AWS_DEFAULT_PROFILE terraform
11. Run 'aws configure' and keep all, except do set default aws region
12. Test aws config with 'aws ec2 describe-instances --profile terraform'. Should get no errors

## deploy the CI/CD pipeline

1. scp -i ~/.ssh/platform-use1.pem infra/platform/docker-compose-swarm.yml docker@54.172.210.245:
2. ssh -i ~/.ssh/platform-use1.pem docker@54.172.210.245
3. docker stack deploy -c docker-compose-swarm.yml pipeline

## Configure Jenkins

1. log into Jenkins
2. configure Jenkins URL
3. configure Jenkins github id
4. configure Jenkins dockerhub id
5. configure github auth and groups
6. configure slack channel
7. configure smtp server
8. configure jobs organization to pull down unisys/{project}-.\*

## Configure SonarQube

1. log into SonarQube
2. configure SonarQube github id

## Things that could potentially hurt our one-click deployment

### terraform init

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

- provider.local: version = "~> 1.3"
- provider.null: version = "~> 2.1"
- provider.template: version = "~> 2.1"

Since our setup gets the latest terraform, we could find incompatibilties in the 11th hour with our variables.tf and main.tf.

## Online resources that helped

- https://hackernoon.com/introduction-to-aws-with-terraform-7a8daf261dc0
-

```sh
some code
```
