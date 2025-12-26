# Format-on-Save Setup Guide

This guide explains how to configure your development environment to automatically format code on save, ensuring consistent code style across the Fawkes platform.

## Overview

Fawkes uses multiple formatters to maintain consistent code style:

- **Black**: Python code formatting
- **gofmt**: Go code formatting
- **shfmt**: Shell script formatting
- **Prettier**: JSON, YAML, and Markdown formatting
- **terraform fmt**: Terraform configuration formatting

All formatters are integrated into:

- Pre-commit hooks (automatic)
- CI/CD pipeline (automatic)
- IDE/editor settings (manual setup required)

## Quick Start

### 1. Install Pre-commit Hooks

Pre-commit hooks automatically format code when you commit:

```bash
# Install pre-commit
make pre-commit-setup

# Verify installation
pre-commit run --all-files
```

This will:

- Install all formatter tools
- Set up Git hooks
- Validate configuration

### 2. Configure Your IDE

Choose your IDE and follow the setup instructions below.

## VS Code Setup

### Automatic Setup (Recommended)

Fawkes includes `.vscode/settings.json` and `.vscode/extensions.json` files that configure VS Code automatically.

1. Open the Fawkes repository in VS Code
2. VS Code will prompt you to install recommended extensions
3. Click "Install All" to install:

   - Python extension with Black formatter
   - Go extension
   - Prettier extension
   - Shell Format extension
   - Terraform extension
   - EditorConfig extension

4. Format-on-save is already configured in `.vscode/settings.json`

### Manual Setup

If automatic setup doesn't work, follow these steps:

#### Install Extensions

Open VS Code Extensions (Ctrl+Shift+X / Cmd+Shift+X) and install:

```
ms-python.python
ms-python.black-formatter
golang.go
foxundermoon.shell-format
esbenp.prettier-vscode
hashicorp.terraform
editorconfig.editorconfig
```

#### Configure Settings

Open Settings (Ctrl+, / Cmd+,) and add:

```json
{
  "editor.formatOnSave": true,
  "python.formatting.provider": "black",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },
  "[go]": {
    "editor.defaultFormatter": "golang.go"
  },
  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format"
  },
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  }
}
```

### Verify VS Code Setup

1. Open a Python file (e.g., `services/feedback/app/main.py`)
2. Make a formatting change (add extra spaces)
3. Save the file (Ctrl+S / Cmd+S)
4. The file should automatically format

## IntelliJ IDEA / PyCharm Setup

### Install Plugins

1. Go to **File → Settings → Plugins** (Windows/Linux) or **IntelliJ IDEA → Preferences → Plugins** (macOS)
2. Search and install:
   - **Terraform and HCL** (for Terraform formatting)
   - **Bash Support** (for shell script formatting)
   - **Prettier** (for JSON/YAML/Markdown)

### Configure Python Formatting (PyCharm)

1. Go to **File → Settings → Tools → File Watchers**
2. Click **+** and select **Black**
3. Configure:
   - **Program**: `/path/to/black` (find with `which black`)
   - **Arguments**: `$FilePath$ --line-length=120`
   - **Output paths**: `$FilePath$`
   - **Working directory**: `$ProjectFileDir$`
4. Enable **Auto-save edited files to trigger the watcher**

### Configure Go Formatting

1. Go to **File → Settings → Tools → File Watchers**
2. Click **+** and select **gofmt**
3. Enable **Run on external changes**

### Configure Terraform Formatting

1. Go to **File → Settings → Tools → Terraform**
2. Enable **Format code on save**

### Configure EditorConfig

1. EditorConfig support is built-in and automatic
2. Verify: **File → Settings → Editor → Code Style**
3. Ensure **Enable EditorConfig support** is checked

## Vim/Neovim Setup

### Install Plugins (using vim-plug)

Add to your `~/.vimrc` or `~/.config/nvim/init.vim`:

```vim
" Plugin manager
call plug#begin()

" Formatting plugins
Plug 'ambv/black'                    " Black (Python)
Plug 'dense-analysis/ale'            " Async Lint Engine (multi-language)
Plug 'hashivim/vim-terraform'        " Terraform
Plug 'fatih/vim-go'                  " Go
Plug 'prettier/vim-prettier'         " Prettier

" EditorConfig
Plug 'editorconfig/editorconfig-vim'

call plug#end()
```

### Configure ALE for Auto-formatting

Add to your Vim config:

```vim
" Enable ALE
let g:ale_enabled = 1

" Configure formatters
let g:ale_fixers = {
\   'python': ['black'],
\   'go': ['gofmt'],
\   'sh': ['shfmt'],
\   'json': ['prettier'],
\   'yaml': ['prettier'],
\   'markdown': ['prettier'],
\   'terraform': ['terraform'],
\}

" Format on save
let g:ale_fix_on_save = 1

" Black configuration
let g:black_linelength = 120

" shfmt configuration
let g:shfmt_extra_args = '-i 2 -ci -bn -sr'
```

### Install formatter binaries

```bash
# Python
pip install black

# Go
# gofmt comes with Go installation

# Shell
brew install shfmt  # macOS
# or
curl -sS https://webinstall.dev/shfmt | bash  # Linux

# Prettier
npm install -g prettier

# Terraform
brew install terraform  # macOS
```

## Emacs Setup

### Install Packages

Add to your `~/.emacs` or `~/.emacs.d/init.el`:

```elisp
;; Package repositories
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install packages
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Python - Black
(use-package python-black
  :ensure t
  :demand t
  :after python
  :hook (python-mode . python-black-on-save-mode))

;; Go - gofmt
(use-package go-mode
  :ensure t
  :hook (before-save . gofmt-before-save))

;; Prettier for JSON/YAML/Markdown
(use-package prettier-js
  :ensure t
  :hook ((json-mode yaml-mode markdown-mode) . prettier-js-mode))

;; Terraform
(use-package terraform-mode
  :ensure t
  :hook (terraform-mode . terraform-format-on-save-mode))

;; EditorConfig
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))
```

## Sublime Text Setup

### Install Package Control

1. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
2. Run: **Install Package Control**

### Install Packages

1. Open Command Palette
2. Run: **Package Control: Install Package**
3. Install these packages:
   - **Python Black**
   - **GoSublime**
   - **Prettify**
   - **Terraform**
   - **EditorConfig**

### Configure Format on Save

Create or edit **Preferences → Settings**:

```json
{
  "format_on_save": true,
  "python_black_command": "black",
  "python_black_options": {
    "line_length": 120
  }
}
```

## Command-Line Formatting

If you prefer not to use IDE integration, you can format manually:

### Format All Files

```bash
# Run all formatters via pre-commit
pre-commit run --all-files

# Or use make target
make lint
```

### Format Specific File Types

```bash
# Python
black --line-length=120 services/**/*.py

# Go
gofmt -w -s jenkins-shared-library/**/*.go

# Shell scripts
shfmt -i 2 -ci -bn -sr -w scripts/**/*.sh

# JSON/YAML/Markdown
prettier --write "**/*.{json,yaml,yml,md}"

# Terraform
terraform fmt -recursive infra/terraform/
```

## Configuration Files

Fawkes includes configuration files for all formatters:

| Formatter | Configuration File          | Purpose                       |
| --------- | --------------------------- | ----------------------------- |
| Black     | `pyproject.toml`            | Python formatting settings    |
| gofmt     | `.golangci.yml`             | Go linting and formatting     |
| shfmt     | `.pre-commit-config.yaml`   | Shell script formatting args  |
| Prettier  | `.prettierrc`               | JSON/YAML/Markdown formatting |
| Terraform | `.terraform-fmt` (implicit) | Terraform formatting          |
| All       | `.editorconfig`             | Cross-editor settings         |

## Troubleshooting

### Format on Save Not Working

**VS Code:**

1. Check that the extension is installed: View → Extensions
2. Check that format on save is enabled: Settings → "Format On Save"
3. Check the default formatter: Settings → "Default Formatter"
4. Check the Output panel: View → Output → Select extension

**IntelliJ/PyCharm:**

1. Check File Watchers are enabled: Settings → Tools → File Watchers
2. Check that the formatter binary is in PATH
3. Try manually formatting: Code → Reformat Code (Ctrl+Alt+L)

### Formatter Not Found

Install the missing formatter:

```bash
# Black
pip install black

# shfmt (macOS)
brew install shfmt

# shfmt (Linux)
curl -sS https://webinstall.dev/shfmt | bash

# Prettier
npm install -g prettier

# Verify installation
which black
which shfmt
which prettier
```

### Conflicting Formatters

If multiple formatters conflict:

1. Check `.editorconfig` settings
2. Verify file associations in IDE settings
3. Ensure only one formatter is set as default per file type

### Pre-commit Hook Failing

If pre-commit hook fails:

```bash
# Update hooks
pre-commit autoupdate

# Clear cache
pre-commit clean

# Reinstall hooks
pre-commit uninstall
pre-commit install

# Run again
pre-commit run --all-files
```

## Best Practices

### DO ✅

- **Enable format-on-save**: Automatic formatting prevents style issues
- **Install EditorConfig extension**: Ensures consistent editor settings
- **Run pre-commit before pushing**: `pre-commit run --all-files`
- **Keep formatters updated**: Run `pre-commit autoupdate` monthly
- **Use project formatter configs**: Don't override with personal settings

### DON'T ❌

- **Don't disable formatters**: They ensure code consistency
- **Don't commit unformatted code**: CI will fail
- **Don't use different formatter versions**: Use versions in `.pre-commit-config.yaml`
- **Don't mix tabs and spaces**: Let formatters handle indentation
- **Don't format files manually**: Let tools do it automatically

## CI/CD Integration

Formatting is automatically checked in CI/CD:

```yaml
# .github/workflows/pre-commit.yml
- name: Run pre-commit
  run: pre-commit run --all-files
```

If formatting fails in CI:

1. Pull the latest code
2. Run `pre-commit run --all-files` locally
3. Review and commit the formatting changes
4. Push to your branch

## Getting Help

- **Documentation**: [Code Quality Standards](./code-quality-standards.md)
- **GitHub Issues**: [Report issues](https://github.com/paruff/fawkes/issues)
- **Mattermost**: #platform-help channel

## Related Documentation

- [Code Quality Standards](./code-quality-standards.md)
- [Pre-commit Hooks](../../contributing.md#pre-commit-hooks)
- [CI/CD Pipeline](../../reference/cicd-pipeline.md)

---

**Last Updated**: December 2024
**Related Issues**: #110 (Automated Code Formatting)
