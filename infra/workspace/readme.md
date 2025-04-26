# Fawkes Workspace Automation

This directory contains scripts and configuration for **automated developer workspace creation** as part of the larger [Fawkes](../../README.md) platform. The goal is to enable every team member to quickly set up a consistent, secure, and fully equipped development environment—on Windows, macOS, and (in the future) Linux.

## Why Use Automated Workspaces?

- **Consistency:** Every developer gets the same tools, versions, and configuration, reducing "works on my machine" issues.
- **Collaboration:** Identical environments make it easier to pair program, troubleshoot, and share solutions.
- **Speed:** New team members can onboard in minutes, not days.
- **Future-Proof:** Plans to support browser-based/online workspaces for even greater flexibility.

## Supported Platforms

- **Windows:** Automated setup via Chocolatey and PowerShell/batch scripts.
- **macOS:** Automated setup via Homebrew and shell scripts.
- **Linux:** Planned for future releases.
- **Online Workspaces:** (e.g., GitHub Codespaces, Eclipse Che) are under consideration.

## Usage

### 1. Local Workspace Setup

- **Windows:**  
  Run `bootstrap.ps1` (PowerShell) or `space-setup-win10.bat` (Batch) as Administrator.
- **macOS:**  
  Run `space-setup-macos.sh`.
- **Linux:**  
  (Coming soon) Run `space-setup-linux.sh`.

### 2. Validate Your Workspace

- Run integration tests to verify your environment:
  ```sh
  inspec exec test/integration/default
  ```

- Use [Test Kitchen](https://kitchen.ci/) to converge and test workspace builds:
  ```sh
  kitchen converge
  ```

## Contributing

Contributions to improve cross-platform support, add new tools, or enable online workspaces are welcome! See the main [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

---

*Fawkes Workspace Automation: Making every developer's environment reliable, reproducible, and ready for collaboration.*