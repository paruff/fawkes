# Team Onboarding Guide

Welcome to the Fawkes project! This guide will help new team members get access to the tools, repositories, and resources needed to contribute effectively. It also provides tips for learning about the platform and setting up your development workspace.

---

## 1. Access to Repositories and Tools

- **GitHub:**  
  Ask your team lead or project admin to invite you to the [paruff/fawkes GitHub organization](https://github.com/paruff/fawkes).  
  Once invited, accept the invitation via email or directly on GitHub.

- **Jira or Issue Tracker:**  
  If your team uses Jira or another issue tracker, request access from your project admin.

- **Slack or Communication Tools:**  
  Join the team’s communication channels (e.g., Slack, Teams) for updates and collaboration.

---

## 2. Set Up Your Development Workspace

Follow these steps to set up your local development environment:

1. **Review the Workspace Automation Guide**:  
   Refer to the [Workspace Automation Guide](infra/workspace/readme.md) for detailed instructions.

2. **Run the Setup Script**:  
   Use the provided script for your operating system:
   - **Windows**:  
     Run the PowerShell script as Administrator:
     ```sh
     ./setup-win-space.ps1
     ```
   - **macOS**:  
     Run the shell script:
     ```sh
     ./setup-macos-space.sh
     ```
   - **Linux**:  
     (Coming soon) Run the Linux setup script:
     ```sh
     ./setup-linux-space.sh
     ```

3. **Validate Your Workspace**:  
   After setup, validate your environment:
   - Run integration tests:
     ```sh
     inspec exec test/integration/default
     ```
   - Check installed tools and configurations:
     ```sh
     terraform --version
     kubectl version --client
     helm version
     ```

4. **Troubleshooting**:  
   If you encounter issues, check the Troubleshooting section or open a GitHub Issue.

---

## 3. Learn About the Platform

1. **Read the Main README**:  
   Start with the Fawkes README for an overview of the platform, its goals, and architecture.

2. **Explore the Infrastructure**:  
   Review the Infrastructure Guide to understand how Kubernetes clusters and supporting resources are provisioned.

3. **Understand the Platform Layer**:  
   Learn about CI/CD pipelines, monitoring, and other platform components in the Platform Infrastructure Guide.

4. **Workspace Automation**:  
   Familiarize yourself with the Workspace Automation Guide to understand how developer environments are standardized.

---

## 4. Where to Get Help

- **GitHub Issues**:  
  Report bugs or request features in the [GitHub Issues](https://github.com/paruff/fawkes/issues) section.

- **Documentation**:  
  Check the [docs](http://_vscodecontentref_/3) directory and READMEs throughout the repository for detailed guides and references.

- **Team Support**:  
  Reach out to your team lead or a senior developer for assistance.

---

## 5. Additional Tips

- **Pair Programming**:  
  Pair with another team member for your first setup to learn best practices and resolve issues quickly.

- **Contributing Guide**:  
  Review the Contributing Guide for coding standards, workflows, and guidelines.

- **Stay Updated**:  
  Regularly check the repository for updates to scripts, tools, and documentation.

---

_Welcome to the team! Your contributions help make Fawkes better for everyone._
