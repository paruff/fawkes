import pytest
import os
import sys
import requests
from kubernetes import client, config

# Ensure Argo CD bootstrap step definitions are registered early as a pytest plugin
# Make repository root importable when pytest rootdir is tests/bdd
_HERE = os.path.dirname(__file__)
_ROOT = os.path.abspath(os.path.join(_HERE, "..", ".."))
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)

pytest_plugins = ("tests.bdd.step_definitions.argocd_steps",)

@pytest.fixture(scope='session')
def fawkes_api_url():
    """Base URL for Fawkes API"""
    return 'http://fawkes-api.local/api/v1'

@pytest.fixture(scope='session')
def jenkins_url():
    """Jenkins URL"""
    return 'http://jenkins.fawkes.local'

@pytest.fixture(scope='session')
def k8s_config():
    """Load Kubernetes configuration"""
    config.load_kube_config()

@pytest.fixture
def context():
    """Shared context for test scenarios"""
    return {}

@pytest.fixture
def cleanup_workspace(fawkes_api_url):
    """Cleanup workspaces after tests"""
    created_workspaces = []

    yield created_workspaces

    # Cleanup
    for workspace_id in created_workspaces:
        try:
            requests.delete(f"{fawkes_api_url}/workspaces/{workspace_id}")
        except Exception as e:
            print(f"Failed to cleanup workspace {workspace_id}: {e}")

@pytest.fixture(autouse=True)
def dora_metrics_tracking(request):
    """Track DORA metrics for each test"""
    markers = [m.name for m in request.node.iter_markers()]
    dora_markers = [m for m in markers if m.startswith('dora-')]

    yield

    # After test completes, record metrics
    if dora_markers and hasattr(request.node, 'rep_call'):
        duration = request.node.rep_call.duration
        outcome = request.node.rep_call.outcome

        # Send to metrics collector
        for marker in dora_markers:
            metric_type = marker.replace('dora-', '')
            # Implementation to send to your metrics system

@pytest.fixture
def kubectl_helper():
    """Mock kubectl helper for BDD tests."""
    
    class KubectlHelper:
        """Mock implementation of kubectl operations."""
        
        def __init__(self):
            self._namespaces = ['fawkes', 'default', 'kube-system']
        
        def get_namespaces(self):
            """Get list of namespaces."""
            return self._namespaces
        
        def get_deployment(self, name, namespace):
            """Get deployment by name."""
            if name == 'jenkins' and namespace == 'fawkes':
                return {
                    'name': 'jenkins',
                    'namespace': 'fawkes',
                    'replicas': 1,
                    'ready_replicas': 1
                }
            return None
        
        def get_pods_by_label(self, label, namespace):
            """Get pods matching label selector."""
            if 'jenkins' in label.lower():
                return [{
                    'name': 'jenkins-0',
                    'namespace': namespace,
                    'status': 'Running',
                    'ready': True,
                    'labels': {'app.kubernetes.io/name': 'jenkins'}
                }]
            return []
        
        def get_service(self, name, namespace):
            """Get service by name."""
            if name == 'jenkins':
                return {
                    'name': 'jenkins',
                    'namespace': namespace,
                    'type': 'ClusterIP',
                    'ports': [{'port': 8080, 'targetPort': 8080}]
                }
            return None
        
        def get_ingress(self, name, namespace):
            """Get ingress by name."""
            if name == 'jenkins':
                return {
                    'name': 'jenkins',
                    'namespace': namespace,
                    'className': 'nginx',
                    'hosts': ['jenkins.127.0.0.1.nip.io']
                }
            return None
    
    return KubectlHelper()


@pytest.fixture
def jenkins_api_helper():
    """Mock Jenkins API helper for BDD tests."""
    
    class JenkinsAPIHelper:
        """Mock implementation of Jenkins API operations."""
        
        def __init__(self):
            self._authenticated = False
            self._config = {
                'clouds': [{
                    'name': 'kubernetes',
                    'namespace': 'fawkes',
                    'jenkinsUrl': 'http://jenkins:8080',
                    'jenkinsTunnel': 'jenkins-agent:50000',
                    'containerCapStr': '20',
                    'templates': [
                        {
                            'name': 'jnlp-agent',
                            'label': 'k8s-agent',
                            'containers': [
                                {'image': 'jenkins/inbound-agent:latest'}
                            ],
                            'instanceCapStr': '10',
                            'idleTerminationMinutes': 10
                        },
                        {
                            'name': 'maven-agent',
                            'label': 'maven java',
                            'containers': [
                                {
                                    'image': 'maven:3.9-eclipse-temurin-17',
                                    'resourceRequestCpu': '1',
                                    'resourceRequestMemory': '2Gi',
                                    'resourceLimitCpu': '2',
                                    'resourceLimitMemory': '4Gi'
                                },
                                {'image': 'jenkins/inbound-agent:latest'}
                            ],
                            'instanceCapStr': '5',
                            'idleTerminationMinutes': 10
                        },
                        {
                            'name': 'python-agent',
                            'label': 'python',
                            'containers': [
                                {'image': 'python:3.11-slim'},
                                {'image': 'jenkins/inbound-agent:latest'}
                            ],
                            'instanceCapStr': '5',
                            'idleTerminationMinutes': 10
                        },
                        {
                            'name': 'node-agent',
                            'label': 'node nodejs',
                            'containers': [
                                {'image': 'node:20-slim'},
                                {'image': 'jenkins/inbound-agent:latest'}
                            ],
                            'instanceCapStr': '5',
                            'idleTerminationMinutes': 10
                        },
                        {
                            'name': 'go-agent',
                            'label': 'go golang',
                            'containers': [
                                {'image': 'golang:1.21'},
                                {'image': 'jenkins/inbound-agent:latest'}
                            ],
                            'instanceCapStr': '5',
                            'idleTerminationMinutes': 10
                        }
                    ]
                }]
            }
            self._system_message = 'Fawkes CI/CD Platform - Golden Path Enabled'
            self._executor_count = 0
        
        def get_configuration(self):
            """Get Jenkins configuration."""
            return self._config
        
        def login(self, username, password):
            """Login to Jenkins."""
            if username == 'admin' and password == 'fawkesidp':
                self._authenticated = True
                return True
            return False
        
        def is_authenticated(self):
            """Check if authenticated."""
            return self._authenticated
        
        def get_system_message(self):
            """Get Jenkins system message."""
            return self._system_message
        
        def get_executor_count(self):
            """Get number of executors on controller."""
            return self._executor_count
        
        def run_test_job(self, label):
            """Simulate running a test job with specific agent label."""
            templates = self._config['clouds'][0]['templates']
            matching_templates = [t for t in templates if label in t.get('label', '')]
            return len(matching_templates) > 0
    
    return JenkinsAPIHelper()