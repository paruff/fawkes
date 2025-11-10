#!/usr/bin/env python3
"""
Fawkes CLI - Command Line Interface for Fawkes Platform

This is the main CLI tool that provides all the commands referenced
in the documentation and lab automation.

Installation:
    pip install fawkes-cli

    Or from source:
    git clone https://github.com/fawkes-platform/fawkes-cli
    cd fawkes-cli
    pip install -e .

Usage:
    fawkes --help
    fawkes lab start --module 1
    fawkes lab validate --lab white-belt-lab1
    fawkes assessment validate --belt white
"""

import click
import subprocess
import yaml
import json
import os
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict

# Import the lab automation classes we created earlier
# In a real package, these would be in separate modules
from lab_automation import (
    FawkesLabCLI,
    AssessmentValidator,
    LabAutomation,
    setup_lab_environment,
    cleanup_lab_environment
)

# Version
__version__ = "1.0.0"

# Configuration
FAWKES_HOME = Path.home() / ".fawkes"
CONFIG_FILE = FAWKES_HOME / "config.yaml"
LABS_DIR = Path(__file__).parent / "labs"


class FawkesConfig:
    """Manage Fawkes CLI configuration"""

    def __init__(self):
        self.config_file = CONFIG_FILE
        self.config = self.load_config()

    def load_config(self) -> Dict:
        """Load configuration from file"""
        if not self.config_file.exists():
            return self.default_config()

        with open(self.config_file, 'r') as f:
            return yaml.safe_load(f)

    def save_config(self):
        """Save configuration to file"""
        FAWKES_HOME.mkdir(parents=True, exist_ok=True)
        with open(self.config_file, 'w') as f:
            yaml.dump(self.config, f)

    def default_config(self) -> Dict:
        """Default configuration"""
        return {
            'cluster': {
                'context': 'default',
                'namespace_prefix': 'lab'
            },
            'labs': {
                'timeout': 3600,
                'auto_cleanup': True
            },
            'user': {
                'email': None,
                'name': None
            }
        }

    def get(self, key: str, default=None):
        """Get config value"""
        keys = key.split('.')
        value = self.config
        for k in keys:
            value = value.get(k, {})
        return value if value != {} else default

    def set(self, key: str, value):
        """Set config value"""
        keys = key.split('.')
        config = self.config
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]
        config[keys[-1]] = value
        self.save_config()


# Global config instance
config = FawkesConfig()


# =============================================================================
# CLI GROUPS
# =============================================================================

@click.group()
@click.version_option(version=__version__)
@click.pass_context
def cli(ctx):
    """
    Fawkes CLI - Platform Engineering Training Tool

    Manage lab environments, validate assessments, and track progress
    through the Fawkes Dojo curriculum.

    Examples:
        fawkes lab start --module 1
        fawkes lab validate --lab white-belt-lab1
        fawkes assessment validate --belt white
    """
    ctx.ensure_object(dict)


# =============================================================================
# LAB COMMANDS
# =============================================================================

@cli.group()
def lab():
    """Manage lab environments"""
    pass


@lab.command()
@click.option('--module', '-m', type=int, required=True, help='Module number (1-20)')
@click.option('--user', '-u', help='User email for multi-user environments')
def start(module: int, user: Optional[str]):
    """Start a lab environment for a specific module"""

    click.echo(f"🚀 Starting lab environment for Module {module}...")

    # Get user info
    if not user:
        user = config.get('user.email')
        if not user:
            user = click.prompt('Enter your email')
            config.set('user.email', user)

    # Create lab environment
    lab_cli = FawkesLabCLI()

    try:
        lab_cli.start_lab(module)
        click.echo(f"✅ Lab environment ready!")
        click.echo(f"\n📚 Next steps:")
        click.echo(f"   1. Review Module {module} content")
        click.echo(f"   2. Complete hands-on exercises")
        click.echo(f"   3. Run: fawkes lab validate --lab [lab-name]")
        click.echo(f"\n   Documentation: https://docs.fawkes.io/dojo/module-{module}")
    except Exception as e:
        click.echo(f"❌ Error starting lab: {str(e)}", err=True)
        sys.exit(1)


@lab.command()
@click.option('--lab', '-l', required=True, help='Lab name (e.g., white-belt-lab1)')
@click.option('--verbose', '-v', is_flag=True, help='Show detailed validation output')
def validate(lab: str, verbose: bool):
    """Validate lab completion"""

    click.echo(f"🔍 Validating {lab}...")

    lab_cli = FawkesLabCLI()

    try:
        result = lab_cli.validate_lab(lab)

        if result.passed:
            click.echo(f"✅ PASSED: {result.message}")
            click.echo(f"   Score: {result.points}/{result.max_points} points")

            if verbose and result.details:
                click.echo("\n   Checks:")
                for check in result.details.get('checks', []):
                    click.echo(f"      ✓ {check}")

            click.echo("\n🎉 Great job! You can move to the next lab.")
        else:
            click.echo(f"❌ FAILED: {result.message}")
            click.echo(f"   Score: {result.points}/{result.max_points} points")

            if result.details:
                click.echo("\n   Failed checks:")
                for check in result.details.get('checks', []):
                    click.echo(f"      • {check}")

            click.echo("\n💡 Review the failed checks and try again.")
            click.echo("   Need help? Visit #dojo-support on Mattermost")
            sys.exit(1)

    except KeyError:
        click.echo(f"❌ Unknown lab: {lab}", err=True)
        click.echo(f"   Available labs: white-belt-lab1, white-belt-lab2, ...", err=True)
        sys.exit(1)
    except Exception as e:
        click.echo(f"❌ Validation error: {str(e)}", err=True)
        sys.exit(1)


@lab.command()
@click.option('--module', '-m', type=int, required=True, help='Module number')
@click.option('--force', is_flag=True, help='Force cleanup without confirmation')
def stop(module: int, force: bool):
    """Stop and cleanup a lab environment"""

    if not force:
        click.confirm(f'Are you sure you want to cleanup lab for Module {module}?', abort=True)

    click.echo(f"🧹 Cleaning up lab environment for Module {module}...")

    try:
        cleanup_lab_environment(module)
        click.echo(f"✅ Lab environment cleaned up!")
    except Exception as e:
        click.echo(f"❌ Cleanup error: {str(e)}", err=True)
        sys.exit(1)


@lab.command(name='list')
def list_labs():
    """List all running lab environments"""

    click.echo("📋 Active lab environments:")

    try:
        result = subprocess.run(
            ['kubectl', 'get', 'namespaces', '-l', 'fawkes.io/lab', '-o', 'json'],
            capture_output=True,
            text=True,
            check=True
        )

        namespaces = json.loads(result.stdout)

        if not namespaces.get('items'):
            click.echo("   No active labs found")
            return

        for ns in namespaces['items']:
            name = ns['metadata']['name']
            labels = ns['metadata'].get('labels', {})
            module = labels.get('fawkes.io/module', 'unknown')
            created = ns['metadata']['creationTimestamp']

            click.echo(f"   • {name}")
            click.echo(f"     Module: {module}, Created: {created}")

    except subprocess.CalledProcessError as e:
        click.echo(f"❌ Error listing labs: {e.stderr}", err=True)
        sys.exit(1)


@lab.command()
@click.option('--module', '-m', type=int, required=True, help='Module number')
def status(module: int):
    """Check status of a lab environment"""

    namespace = f"lab-module-{module}"

    click.echo(f"📊 Lab Status: Module {module}")
    click.echo(f"   Namespace: {namespace}\n")

    try:
        # Get all resources
        result = subprocess.run(
            ['kubectl', 'get', 'all', '-n', namespace],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            click.echo(f"❌ Lab not found. Start with: fawkes lab start --module {module}")
            sys.exit(1)

        click.echo(result.stdout)

    except Exception as e:
        click.echo(f"❌ Error checking status: {str(e)}", err=True)
        sys.exit(1)


@lab.command()
@click.option('--module', '-m', type=int, required=True, help='Module number')
@click.option('--follow', '-f', is_flag=True, help='Follow log output')
def logs(module: int, follow: bool):
    """View logs from lab environment"""

    namespace = f"lab-module-{module}"

    try:
        cmd = ['kubectl', 'logs', '-n', namespace, '-l', 'app=my-first-app']
        if follow:
            cmd.append('-f')

        subprocess.run(cmd)

    except KeyboardInterrupt:
        click.echo("\n👋 Stopped following logs")
    except Exception as e:
        click.echo(f"❌ Error viewing logs: {str(e)}", err=True)
        sys.exit(1)


# =============================================================================
# ASSESSMENT COMMANDS
# =============================================================================

@cli.group()
def assessment():
    """Manage belt assessments"""
    pass


@assessment.command()
@click.option('--belt', '-b', required=True,
              type=click.Choice(['white', 'yellow', 'green', 'brown', 'black']),
              help='Belt level')
def validate(belt: str):
    """Validate complete belt assessment"""

    click.echo(f"🎓 Validating {belt.upper()} Belt Assessment...\n")

    validator = AssessmentValidator()

    try:
        result = validator.validate_assessment(belt)

        # Display results
        click.echo("=" * 60)
        click.echo(f"   {result['belt'].upper()} BELT ASSESSMENT RESULTS")
        click.echo("=" * 60)
        click.echo(f"\n   Total Score: {result['total_points']}/{result['max_points']} ({result['percentage']:.1f}%)")
        click.echo(f"   Passing Threshold: {result['passing_threshold']}%")

        if result['passed']:
            click.echo(f"\n   ✅ PASSED - Congratulations!")
            click.echo(f"\n   You have earned the {result['belt'].upper()} Belt certification!")
            click.echo(f"\n   Next steps:")
            click.echo(f"   1. Check your email for certificate")
            click.echo(f"   2. Add badge to LinkedIn")
            click.echo(f"   3. Continue to next belt level")
        else:
            click.echo(f"\n   ❌ NOT PASSED")
            click.echo(f"   You need {result['passing_threshold']}% to pass.")
            click.echo(f"   Review the areas where you lost points and try again.")

        click.echo("\n   Lab Results:")
        for lab in result['labs']:
            status = "✅" if lab['passed'] else "❌"
            click.echo(f"      {status} {lab['lab']}: {lab['points']}/{lab['max_points']}")

        click.echo("=" * 60 + "\n")

        if not result['passed']:
            sys.exit(1)

    except Exception as e:
        click.echo(f"❌ Assessment error: {str(e)}", err=True)
        sys.exit(1)


@assessment.command(name='check-eligibility')
@click.option('--belt', '-b', required=True,
              type=click.Choice(['white', 'yellow', 'green', 'brown', 'black']))
def check_eligibility(belt: str):
    """Check if you're eligible to take an assessment"""

    click.echo(f"🔍 Checking eligibility for {belt.upper()} Belt Assessment...")

    # Check prerequisites
    prerequisites = {
        'white': [],
        'yellow': ['white'],
        'green': ['white', 'yellow'],
        'brown': ['white', 'yellow', 'green'],
        'black': ['white', 'yellow', 'green', 'brown']
    }

    required = prerequisites[belt]

    if not required:
        click.echo(f"✅ No prerequisites for {belt.upper()} Belt")
        click.echo(f"   You can schedule your assessment now!")
        return

    click.echo(f"\n   Required prerequisites:")
    for req in required:
        # In real implementation, would check certification database
        click.echo(f"      • {req.upper()} Belt certification")

    click.echo(f"\n   Run: fawkes assessment schedule --belt {belt}")


@assessment.command()
@click.option('--belt', '-b', required=True,
              type=click.Choice(['white', 'yellow', 'green', 'brown', 'black']))
@click.option('--date', '-d', help='Date (YYYY-MM-DD)')
@click.option('--time', '-t', help='Time (HH:MM)')
def schedule(belt: str, date: Optional[str], time: Optional[str]):
    """Schedule an assessment"""

    if not date:
        date = click.prompt('Assessment date (YYYY-MM-DD)')

    if not time:
        time = click.prompt('Assessment time (HH:MM)')

    click.echo(f"\n📅 Scheduling {belt.upper()} Belt Assessment:")
    click.echo(f"   Date: {date}")
    click.echo(f"   Time: {time}")
    click.echo(f"\n✅ Assessment scheduled!")
    click.echo(f"\n   You will receive a confirmation email with:")
    click.echo(f"   • Assessment link")
    click.echo(f"   • Duration and format")
    click.echo(f"   • Requirements checklist")


# =============================================================================
# CONFIG COMMANDS
# =============================================================================

@cli.group()
def config():
    """Manage Fawkes CLI configuration"""
    pass


@config.command()
@click.argument('key')
@click.argument('value')
def set(key: str, value: str):
    """Set a configuration value"""

    config.set(key, value)
    click.echo(f"✅ Set {key} = {value}")


@config.command()
@click.argument('key')
def get(key: str):
    """Get a configuration value"""

    value = config.get(key)
    if value:
        click.echo(f"{key} = {value}")
    else:
        click.echo(f"❌ {key} not found")


@config.command(name='list')
def list_config():
    """List all configuration values"""

    click.echo("📋 Fawkes CLI Configuration:\n")
    click.echo(yaml.dump(config.config, default_flow_style=False))


# =============================================================================
# SETUP COMMAND
# =============================================================================

@cli.command()
@click.option('--force', is_flag=True, help='Force reinstall')
def setup(force: bool):
    """Setup Fawkes Dojo infrastructure (one-time)"""

    click.echo("🔧 Setting up Fawkes Dojo lab infrastructure...")

    if not force:
        click.confirm('This will install Prometheus, ArgoCD, Flagger, and other tools. Continue?', abort=True)

    try:
        setup_lab_environment()
        click.echo("\n✅ Lab infrastructure setup complete!")
        click.echo("\n   Next steps:")
        click.echo("   1. Run: fawkes lab start --module 1")
        click.echo("   2. Complete Module 1 exercises")
        click.echo("   3. Run: fawkes lab validate --lab white-belt-lab1")
    except Exception as e:
        click.echo(f"❌ Setup error: {str(e)}", err=True)
        sys.exit(1)


# =============================================================================
# UTILITY COMMANDS
# =============================================================================

@cli.command()
def login():
    """Authenticate with Fawkes platform"""

    click.echo("🔐 Fawkes Platform Login")

    email = click.prompt('Email')
    # In real implementation, would do OAuth or API key auth

    config.set('user.email', email)
    click.echo(f"\n✅ Logged in as {email}")


@cli.command()
def status():
    """Check Fawkes platform status"""

    click.echo("📊 Fawkes Platform Status:\n")

    try:
        # Check cluster connectivity
        result = subprocess.run(
            ['kubectl', 'cluster-info'],
            capture_output=True,
            text=True,
            check=True
        )
        click.echo("✅ Kubernetes cluster: Connected")

        # Check monitoring
        result = subprocess.run(
            ['kubectl', 'get', 'pods', '-n', 'monitoring'],
            capture_output=True,
            text=True
        )
        if 'prometheus' in result.stdout:
            click.echo("✅ Monitoring: Running")
        else:
            click.echo("⚠️  Monitoring: Not installed")

        # Check ArgoCD
        result = subprocess.run(
            ['kubectl', 'get', 'pods', '-n', 'argocd'],
            capture_output=True,
            text=True
        )
        if 'argocd-server' in result.stdout:
            click.echo("✅ ArgoCD: Running")
        else:
            click.echo("⚠️  ArgoCD: Not installed")

        click.echo("\n💡 Run 'fawkes setup' to install missing components")

    except subprocess.CalledProcessError:
        click.echo("❌ Cannot connect to Kubernetes cluster")
        click.echo("   Check: kubectl cluster-info")
        sys.exit(1)


@cli.command()
def version():
    """Show Fawkes CLI version"""

    click.echo(f"Fawkes CLI version {__version__}")


# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

def main():
    """Main entry point for CLI"""
    cli(obj={})


if __name__ == '__main__':
    main()