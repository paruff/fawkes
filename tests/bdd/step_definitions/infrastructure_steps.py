# tests/e2e/step_definitions/infrastructure_steps.py

from pytest_bdd import scenarios, given, when, then, parsers
import subprocess
import boto3
import time

scenarios('../features/infrastructure_provisioning.feature')

@given('I have AWS credentials configured')
def aws_credentials():
    """Verify AWS credentials are available"""
    sts = boto3.client('sts')
    identity = sts.get_caller_identity()
    assert identity['Account'], "AWS credentials not configured"

@given('I have Terraform installed')
def terraform_installed():
    """Verify Terraform is available"""
    result = subprocess.run(['terraform', '--version'], capture_output=True)
    assert result.returncode == 0, "Terraform not installed"

@when(parsers.parse('I run "{command}"'))
def run_command(command):
    """Execute infrastructure provisioning command"""
    # This will be implemented once we have working script
    pass

@then(parsers.parse('the script completes successfully within {minutes:d} minutes'))
def check_completion(minutes):
    # Implementation
    pass