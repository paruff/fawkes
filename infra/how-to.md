# Fawkes Infrastructure Setup Guide

This guide provides step-by-step instructions for setting up the Fawkes infrastructure, configuring AWS, deploying the CI/CD pipeline, and integrating tools like Jenkins and SonarQube.

---

## Table of Contents

1. [Generate SSH Keys](#generate-ssh-keys)
2. [Retrieve AWS Access and Secret Keys](#retrieve-aws-access-and-secret-keys)
3. [Configure AWS CLI](#configure-aws-cli)
4. [Deploy the CI/CD Pipeline](#deploy-the-cicd-pipeline)
5. [Configure Jenkins](#configure-jenkins)
6. [Configure SonarQube](#configure-sonarqube)
7. [Common Issues and Solutions](#common-issues-and-solutions)
8. [Helpful Resources](#helpful-resources)

---

## Generate SSH Keys

1. Log in to the AWS Management Console.
2. Navigate to the **EC2** service.
3. Select **Key Pairs** from the **Resources Dashboard**.
4. Click **Create Key Pair**.
5. Enter a name in the format `platform-{region}` (e.g., `platform-us-east-1`) and click **Create**.
6. Save the key pair file (`.pem`) to your local machine.
7. Open a terminal and ensure the key file has the correct permissions:
   ```sh
   chmod 400 platform-{region}.pem
   ```

---

## Retrieve AWS Access and Secret Keys

1. Log in to the AWS Management Console.
2. Navigate to the **IAM** service.
3. Select **Users** from the left-hand navigation menu.
4. Click on the user you want to configure.
5. Go to the **Security Credentials** tab.
6. Under **Access Keys**, click **Create access key**.
7. Download the `.csv` file containing the keys and save it securely.

---

## Configure AWS CLI

1. Open a terminal and run the following command:
   ```sh
   aws configure
   ```
2. Enter the following details when prompted:

   - **AWS Access Key ID**: (from the `.csv` file)
   - **AWS Secret Access Key**: (from the `.csv` file)
   - **Default region name**: (e.g., `us-east-1`)
   - **Default output format**: (e.g., `json`)

3. Validate the configuration by listing S3 buckets:

   ```sh
   aws s3 ls
   ```

4. (Optional) Create a profile for Terraform:

   - Add the following to `~/.aws/credentials`:
     ```plaintext
     [terraform]
     aws_access_key_id=<your-access-key-id>
     aws_secret_access_key=<your-secret-access-key>
     ```
   - Add the region to `~/.aws/config`:
     ```plaintext
     [profile terraform]
     region=us-east-1
     ```

5. Export the default AWS profile:
   ```sh
   export AWS_DEFAULT_PROFILE=terraform
   ```

---

## Deploy the CI/CD Pipeline

1. Copy the Docker Compose file to the target server:
   ```sh
   scp -i ~/.ssh/platform-{region}.pem infra/platform/docker-compose-swarm.yml docker@<server-ip>:
   ```
2. SSH into the server:
   ```sh
   ssh -i ~/.ssh/platform-{region}.pem docker@<server-ip>
   ```
3. Deploy the pipeline using Docker Stack:
   ```sh
   docker stack deploy -c docker-compose-swarm.yml pipeline
   ```

---

## Configure Jenkins

1. Log in to Jenkins using the admin credentials.
2. Configure the following settings:
   - **Jenkins URL**: Set the base URL for Jenkins.
   - **GitHub Integration**: Add your GitHub credentials and configure repositories.
   - **DockerHub Integration**: Add your DockerHub credentials.
   - **Authentication**: Set up GitHub authentication and group permissions.
   - **Slack Integration**: (Optional) Configure Slack notifications.
   - **SMTP Server**: Configure email notifications.
3. Create a job organization to pull repositories:
   ```plaintext
   unisys/{project}-.*
   ```

---

## Configure SonarQube

1. Log in to SonarQube using the default credentials (`admin` / `admin`).
2. Configure the following settings:
   - **GitHub Integration**: Add your GitHub credentials.
   - **Quality Gates**: Set up quality gates for your projects.

---

## Common Issues and Solutions

### Terraform Version Compatibility

To prevent issues with Terraform provider versions, add version constraints to your `provider` blocks:

```hcl
provider "aws" {
  version = "~> 3.0"
}
```

### AWS CLI Errors

If you encounter errors with the AWS CLI, ensure your credentials and region are correctly configured:

```sh
aws configure
```

---

## Helpful Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)

---

_Fawkes Infra: Deliver fast, deliver better, deliver with confidence._
