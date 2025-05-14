# Fawkes Infrastructure Setup Checklist

This checklist provides step-by-step instructions for setting up the Fawkes infrastructure, configuring AWS, and deploying the CI/CD pipeline. It also outlines the expected outputs for the delivery team.

---

## Prerequisites

Before starting, ensure the following:

1. **AWS CLI**: Install and configure the AWS CLI.  
   [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
2. **Git**: Install Git for cloning the repository.  
   [Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
3. **SSH Keys**: Ensure you have SSH keys for secure access to servers.
4. **Access Credentials**: Obtain AWS access keys and permissions for the required account.

---

## Checklist

### 1. Set Up AWS Client

1. Run the setup script:
   ```sh
   infra/workspace/setup.bat
   ```

## Output from from systems to Delivery team

1. Platform URL to include Jenkins, SonarQube, Nexus
2. AT env URL to load balancer
3. Demo env URL to load balancer
4. URL to ELK load balancer, Centralized log platform
