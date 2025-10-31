import pytest
import requests
from kubernetes import client, config

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