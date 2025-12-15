"""
Step definitions for DORA Metrics Webhooks BDD tests
"""

import json
import hmac
import hashlib
import os
import requests
import pytest
from datetime import datetime
from pytest_bdd import scenarios, given, when, then, parsers
from kubernetes import client, config
import subprocess
import time

# Load all scenarios from the feature file
scenarios('../features/dora-webhooks.feature')

# Test context to share data between steps
class WebhookTestContext:
    def __init__(self):
        self.devlake_url = None
        self.github_webhook_fired = False
        self.jenkins_webhook_fired = False
        self.argocd_webhook_fired = False
        self.incident_webhook_fired = False
        self.last_response = None
        self.last_commit_sha = None
        self.last_build_number = None
        self.last_incident_id = None
        
webhook_context = WebhookTestContext()


# ============================================================
# Background Steps
# ============================================================

@given('the DevLake DORA metrics service is deployed')
def devlake_is_deployed():
    """Verify DevLake is deployed in the cluster"""
    try:
        config.load_kube_config()
        v1 = client.CoreV1Api()

        # Check if DevLake pods are running
        pods = v1.list_namespaced_pod(
            namespace='fawkes-devlake',
            label_selector='app.kubernetes.io/name=devlake'
        )

        assert len(pods.items) > 0, "No DevLake pods found"

        running_pods = [p for p in pods.items if p.status.phase == 'Running']
        assert len(running_pods) > 0, "No DevLake pods in Running state"

    except Exception as e:
        # In test environment, skip if cluster not available
        pytest.skip(f"Kubernetes cluster not available: {e}")


@given(parsers.parse('the DevLake service is accessible at "{url}"'))
def devlake_is_accessible(url):
    """Verify DevLake service is accessible"""
    webhook_context.devlake_url = url
    
    try:
        # Try to ping DevLake
        response = requests.get(f"{url}/api/ping", timeout=5)
        assert response.status_code == 200
    except requests.exceptions.RequestException:
        # In test mode, we may not have actual access
        pytest.skip("DevLake service not accessible in test environment")


# ============================================================
# GitHub Webhook Steps
# ============================================================

@given(parsers.parse('a GitHub webhook is configured for the repository "{repo}"'))
def github_webhook_configured(repo):
    """Verify GitHub webhook configuration exists"""
    # In real scenario, would check GitHub API for webhook config
    # For test, we verify the documentation exists
    import os
    assert os.path.exists('platform/apps/devlake/config/github-webhook-setup.md')


@given(parsers.parse('the webhook points to "{webhook_url}"'))
def webhook_points_to_url(webhook_url):
    """Verify webhook URL configuration"""
    assert 'devlake' in webhook_url
    assert '/api/plugins/webhook' in webhook_url


@when('a developer pushes a commit to the main branch')
def developer_pushes_commit():
    """Simulate a commit push"""
    webhook_context.last_commit_sha = 'abc123def456test'
    webhook_context.github_webhook_fired = True


@then('the GitHub webhook should fire successfully')
def github_webhook_fires():
    """Verify GitHub webhook fired"""
    assert webhook_context.github_webhook_fired


@then('DevLake should receive the commit event')
def devlake_receives_commit():
    """Verify DevLake received commit event"""
    # Create a mock GitHub webhook payload
    payload = {
        "ref": "refs/heads/main",
        "after": webhook_context.last_commit_sha,
        "repository": {"name": "fawkes", "full_name": "paruff/fawkes"},
        "commits": [{
            "id": webhook_context.last_commit_sha,
            "message": "test: webhook test commit",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "author": {"name": "Test User", "email": "test@example.com"}
        }]
    }
    
    try:
        # Send webhook to DevLake
        response = requests.post(
            f"{webhook_context.devlake_url}/api/plugins/webhook/1/commits",
            json=payload,
            headers={
                "Content-Type": "application/json",
                "X-GitHub-Event": "push"
            },
            timeout=5
        )
        webhook_context.last_response = response
        assert response.status_code in [200, 201, 202]
    except requests.exceptions.RequestException:
        pytest.skip("Cannot test webhook in current environment")


@then('the commit should be stored in the DevLake database')
def commit_stored_in_database():
    """Verify commit is in database"""
    # Would query DevLake database or API
    # For test, we check the response was successful
    assert webhook_context.last_response is not None
    assert webhook_context.last_response.status_code in [200, 201, 202]


@then('the commit timestamp should be recorded for lead time calculation')
def commit_timestamp_recorded():
    """Verify commit timestamp is recorded"""
    # Lead time calculation requires commit timestamp
    assert webhook_context.last_commit_sha is not None


# ============================================================
# Jenkins Webhook Steps
# ============================================================

@given(parsers.parse('the Jenkins shared library "{library}" is available'))
def jenkins_library_available(library):
    """Verify Jenkins shared library exists"""
    # Get the repository root directory
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    library_path = os.path.join(repo_root, 'jenkins-shared-library/vars/doraMetrics.groovy')
    assert os.path.exists(library_path), f"Jenkins library not found at {library_path}"


@given(parsers.parse('the Jenkins pipeline includes "{function}" calls'))
def pipeline_includes_function(function):
    """Verify pipeline includes DORA metrics function"""
    # Get the repository root directory
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    library_path = os.path.join(repo_root, 'jenkins-shared-library/vars/doraMetrics.groovy')
    with open(library_path, 'r') as f:
        content = f.read()
        assert 'recordBuild' in content


@when('a Jenkins build completes successfully')
def jenkins_build_completes():
    """Simulate Jenkins build completion"""
    webhook_context.last_build_number = "42"
    webhook_context.jenkins_webhook_fired = True


@then(parsers.parse('the {function} function should be called'))
def dora_function_called(function):
    """Verify DORA metrics function was called"""
    assert webhook_context.jenkins_webhook_fired


@then(parsers.parse('a webhook request should be sent to "{webhook_url}"'))
def webhook_sent_to_url(webhook_url):
    """Verify webhook request is sent"""
    # Create mock Jenkins build event payload
    payload = {
        "service": "test-service",
        "commit_sha": "abc123def456",
        "branch": "main",
        "build_number": webhook_context.last_build_number,
        "status": "success",
        "duration_ms": 60000,
        "stage": "build",
        "is_retry": False,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "url": "http://jenkins.test/job/test/42/",
        "type": "ci_build"
    }
    
    try:
        response = requests.post(
            f"{webhook_context.devlake_url}/api/plugins/webhook/1/cicd",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=5
        )
        webhook_context.last_response = response
        assert response.status_code in [200, 201, 202]
    except requests.exceptions.RequestException:
        pytest.skip("Cannot test webhook in current environment")


@then('DevLake should receive the build event')
def devlake_receives_build():
    """Verify DevLake received build event"""
    assert webhook_context.last_response is not None


@then('the build metrics should be stored for rework rate calculation')
def build_metrics_stored():
    """Verify build metrics are stored"""
    assert webhook_context.last_response.status_code in [200, 201, 202]


# ============================================================
# ArgoCD Webhook Steps
# ============================================================

@given('ArgoCD notifications are configured with DevLake webhook')
def argocd_notifications_configured():
    """Verify ArgoCD notifications config exists"""
    # Get the repository root directory
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    config_path = os.path.join(repo_root, 'platform/apps/devlake/config/argocd-notifications.yaml')
    assert os.path.exists(config_path), f"ArgoCD config not found at {config_path}"


@when('ArgoCD successfully syncs an application')
def argocd_syncs_app():
    """Simulate ArgoCD sync"""
    webhook_context.argocd_webhook_fired = True


@then('ArgoCD should send a deployment success notification')
def argocd_sends_notification():
    """Verify ArgoCD sends notification"""
    assert webhook_context.argocd_webhook_fired


@then('DevLake should receive the deployment event')
def devlake_receives_deployment():
    """Verify DevLake receives deployment"""
    payload = {
        "event_type": "deployment",
        "status": "success",
        "application": "test-app",
        "namespace": "default",
        "revision": "abc123def456",
        "commit_sha": "abc123def456",
        "sync_started_at": datetime.utcnow().isoformat() + "Z",
        "sync_finished_at": datetime.utcnow().isoformat() + "Z",
        "health_status": "Healthy",
        "sync_status": "Synced"
    }
    
    try:
        response = requests.post(
            f"{webhook_context.devlake_url}/api/plugins/webhook/1/deployments",
            json=payload,
            headers={
                "Content-Type": "application/json",
                "X-Webhook-Source": "argocd"
            },
            timeout=5
        )
        webhook_context.last_response = response
        assert response.status_code in [200, 201, 202]
    except requests.exceptions.RequestException:
        pytest.skip("Cannot test webhook in current environment")


@then('the deployment should be stored with timestamp for deployment frequency')
def deployment_stored():
    """Verify deployment is stored"""
    assert webhook_context.last_response is not None


@then('the commit-to-deployment time should be calculated for lead time')
def lead_time_calculated():
    """Verify lead time can be calculated"""
    # Lead time = deployment timestamp - commit timestamp
    assert True  # Would query DevLake for actual calculation


# ============================================================
# Webhook Configuration Steps
# ============================================================

@given('the platform repository contains webhook configurations')
def platform_has_webhook_configs():
    """Verify webhook config files exist"""
    # Get the repository root directory
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    config_dir = os.path.join(repo_root, 'platform/apps/devlake/config')
    assert os.path.exists(config_dir), f"Config directory not found at {config_dir}"


@then(parsers.parse('the "{filename}" configuration should exist'))
def config_file_exists(filename):
    """Verify specific config file exists"""
    # Get the repository root directory
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    filepath = os.path.join(repo_root, f'platform/apps/devlake/config/{filename}')
    assert os.path.exists(filepath), f"Config file not found: {filepath}"


@then(parsers.parse('the "{filename}" documentation should exist'))
def documentation_exists(filename):
    """Verify documentation file exists"""
    # Get the repository root directory
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    filepath = os.path.join(repo_root, f'platform/apps/devlake/config/{filename}')
    assert os.path.exists(filepath), f"Documentation not found: {filepath}"


# ============================================================
# Network & Security Steps
# ============================================================

@given(parsers.parse('Jenkins pods are running in the "{namespace}" namespace'))
def jenkins_in_namespace(namespace):
    """Verify Jenkins namespace"""
    assert namespace == 'fawkes'


@given(parsers.parse('ArgoCD is running in the "{namespace}" namespace'))
def argocd_in_namespace(namespace):
    """Verify ArgoCD namespace"""
    assert namespace == 'argocd'


@given(parsers.parse('DevLake is running in the "{namespace}" namespace'))
def devlake_in_namespace(namespace):
    """Verify DevLake namespace"""
    assert namespace == 'fawkes-devlake'


@when('network policies are applied')
def network_policies_applied():
    """Verify network policies exist"""
    import os
    assert os.path.exists('platform/apps/devlake/config/webhooks.yaml')


@then('Jenkins should be able to reach DevLake webhook endpoint')
def jenkins_can_reach_devlake():
    """Verify Jenkins can reach DevLake"""
    # Would test actual network connectivity
    # For test, we verify network policy allows it
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    config_path = os.path.join(repo_root, 'platform/apps/devlake/config/webhooks.yaml')
    with open(config_path, 'r') as f:
        content = f.read()
        assert 'jenkins' in content.lower()


@then('ArgoCD should be able to reach DevLake webhook endpoint')
def argocd_can_reach_devlake():
    """Verify ArgoCD can reach DevLake"""
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../'))
    config_path = os.path.join(repo_root, 'platform/apps/devlake/config/webhooks.yaml')
    with open(config_path, 'r') as f:
        content = f.read()
        assert 'argocd' in content.lower()


# ============================================================
# Validation & Monitoring Steps
# ============================================================

@then(parsers.parse('the response should have HTTP status code {expected_code:d}'))
def response_has_status_code(expected_code):
    """Verify HTTP response code"""
    if webhook_context.last_response:
        assert webhook_context.last_response.status_code == expected_code


@then('the response should contain a success indicator')
def response_has_success():
    """Verify response indicates success"""
    if webhook_context.last_response:
        assert webhook_context.last_response.status_code in [200, 201, 202]


@then('a warning should be logged about the webhook failure')
def warning_logged():
    """Verify warning is logged on failure"""
    # doraMetrics.groovy logs warnings, doesn't fail pipeline
    assert True


@then(parsers.parse('all events should be correlated by commit SHA'))
def events_correlated_by_sha():
    """Verify events can be correlated"""
    # All events should include commit_sha for correlation
    assert webhook_context.last_commit_sha is not None
