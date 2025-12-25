"""
Pytest configuration and fixtures for Fawkes platform testing.

This file provides:
- Shared fixtures for all tests (Kubernetes, Jenkins, GitHub, etc.)
- Custom pytest markers for categorization
- Test collection hooks for auto-tagging
- Report generation hooks for DORA metrics

Usage:
    Import fixtures in test files:

    def test_something(kubernetes_client, jenkins_api):
        # fixtures are automatically available

    Use markers to categorize:

    @pytest.mark.unit
    @pytest.mark.dora_deployment_frequency
    def test_deployment():
        pass
"""

import os
import uuid
import pytest
import logging
from typing import Generator, Dict, Any
from datetime import datetime
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)


# ============================================================================
# PYTEST CONFIGURATION
# ============================================================================


def pytest_configure(config):
    """
    Register custom markers for test categorization.

    Markers are used to:
    - Organize tests by type (unit, integration, e2e)
    - Tag tests by DORA metric impact
    - Associate tests with dojo belt levels
    - Mark tests as smoke, security, performance, etc.
    """
    # Test type markers
    config.addinivalue_line("markers", "unit: Unit tests (fast, isolated, no external dependencies)")
    config.addinivalue_line("markers", "integration: Integration tests (external dependencies required)")
    config.addinivalue_line("markers", "e2e: End-to-end tests (full system, slowest)")

    # Special test categories
    config.addinivalue_line("markers", "smoke: Critical path smoke tests (run on every commit)")
    config.addinivalue_line("markers", "security: Security-focused tests")
    config.addinivalue_line("markers", "performance: Performance and load tests")
    config.addinivalue_line("markers", "slow: Slow-running tests (run less frequently)")
    config.addinivalue_line("markers", "accessibility: Accessibility testing related tests")
    config.addinivalue_line("markers", "wcag: WCAG compliance tests")
    config.addinivalue_line("markers", "lighthouse: Lighthouse CI tests")
    config.addinivalue_line("markers", "a11y: Accessibility (a11y) shorthand marker")
    config.addinivalue_line("markers", "critical: Critical tests that must pass")
    config.addinivalue_line("markers", "important: Important tests (high priority)")
    config.addinivalue_line("markers", "normal: Normal priority tests")

    # DORA capability markers
    config.addinivalue_line("markers", "dora_deployment_frequency: Tests that measure/improve deployment frequency")
    config.addinivalue_line("markers", "dora_lead_time: Tests that measure/improve lead time for changes")
    config.addinivalue_line("markers", "dora_change_failure_rate: Tests that measure/improve change failure rate")
    config.addinivalue_line("markers", "dora_mttr: Tests that measure/improve mean time to restore")

    # Dojo belt level markers
    config.addinivalue_line("markers", "white_belt: White belt curriculum tests (fundamentals)")
    config.addinivalue_line("markers", "yellow_belt: Yellow belt curriculum tests (CI/CD)")
    config.addinivalue_line("markers", "green_belt: Green belt curriculum tests (GitOps)")
    config.addinivalue_line("markers", "brown_belt: Brown belt curriculum tests (Observability)")
    config.addinivalue_line("markers", "black_belt: Black belt curriculum tests (Architecture)")

    # Sprint markers
    config.addinivalue_line("markers", "sprint_01: Tests for Sprint 01 scope")
    config.addinivalue_line("markers", "sprint_02: Tests for Sprint 02 scope")


def pytest_collection_modifyitems(config, items):
    """
    Automatically tag tests based on their location and content.

    This hook runs after test collection and:
    1. Auto-tags tests based on directory (unit/integration/e2e)
    2. Adds DORA capability tags based on test name
    3. Ensures proper marker hierarchy
    """
    for item in items:
        # Auto-tag based on test directory location
        test_path = str(item.fspath)

        if "tests/unit" in test_path:
            item.add_marker(pytest.mark.unit)
        elif "tests/integration" in test_path:
            item.add_marker(pytest.mark.integration)
        elif "tests/e2e" in test_path:
            item.add_marker(pytest.mark.e2e)

        # Auto-tag DORA capabilities based on test name
        test_name = item.name.lower()

        if any(word in test_name for word in ["deploy", "deployment", "release"]):
            item.add_marker(pytest.mark.dora_deployment_frequency)

        if any(word in test_name for word in ["commit", "lead_time", "velocity"]):
            item.add_marker(pytest.mark.dora_lead_time)

        if any(word in test_name for word in ["fail", "failure", "rollback", "revert"]):
            item.add_marker(pytest.mark.dora_change_failure_rate)

        if any(word in test_name for word in ["incident", "restore", "mttr", "recovery"]):
            item.add_marker(pytest.mark.dora_mttr)


def pytest_terminal_summary(terminalreporter, exitstatus, config):
    """
    Generate custom test summary report.

    Displays:
    - Test counts by category
    - DORA metrics coverage
    - Dojo progression summary
    - Sprint progress
    """
    # Test category summary
    terminalreporter.write_sep("=", "Test Summary by Category")

    categories = {"unit": [], "integration": [], "e2e": [], "smoke": [], "security": []}

    for report in terminalreporter.stats.get("passed", []):
        for category in categories.keys():
            if category in report.keywords:
                categories[category].append(report)

    for category, tests in categories.items():
        icon = "✅" if tests else "⏸️"
        terminalreporter.write_line(f"  {icon} {category.upper()}: {len(tests)} tests passed")

    # DORA metrics coverage
    terminalreporter.write_sep("=", "DORA Metrics Coverage")

    dora_metrics = {"dora_deployment_frequency": 0, "dora_lead_time": 0, "dora_change_failure_rate": 0, "dora_mttr": 0}

    for report in terminalreporter.stats.get("passed", []):
        for metric in dora_metrics.keys():
            if metric in report.keywords:
                dora_metrics[metric] += 1

    for metric, count in dora_metrics.items():
        metric_name = metric.replace("dora_", "").replace("_", " ").title()
        icon = "📊" if count > 0 else "⏸️"
        terminalreporter.write_line(f"  {icon} {metric_name}: {count} tests")

    # Dojo progression summary
    terminalreporter.write_sep("=", "Dojo Progression Summary")

    belt_levels = ["white_belt", "yellow_belt", "green_belt", "brown_belt", "black_belt"]
    belt_emoji = {"white_belt": "🥋", "yellow_belt": "🟡", "green_belt": "🟢", "brown_belt": "🟤", "black_belt": "⚫"}

    for belt in belt_levels:
        count = sum(1 for report in terminalreporter.stats.get("passed", []) if belt in report.keywords)
        emoji = belt_emoji.get(belt, "🎯")
        status = "✅" if count > 0 else "⏸️"
        belt_name = belt.replace("_", " ").title()
        terminalreporter.write_line(f"  {status} {emoji} {belt_name}: {count} scenarios")


# ============================================================================
# SESSION-SCOPED FIXTURES (Set up once per test session)
# ============================================================================


@pytest.fixture(scope="session")
def test_namespace() -> str:
    """
    Generate a unique namespace for this test session.

    Returns:
        str: Namespace name like 'test-a1b2c3d4'
    """
    return f"test-{uuid.uuid4().hex[:8]}"


@pytest.fixture(scope="session")
def test_data_dir() -> Path:
    """
    Directory for test data files.

    Returns:
        Path: Path to tests/data/ directory
    """
    data_dir = Path(__file__).parent / "data"
    data_dir.mkdir(exist_ok=True)
    return data_dir


@pytest.fixture(scope="session")
def aws_region() -> str:
    """
    AWS region for testing.

    Returns:
        str: AWS region (from env or default to us-east-1)
    """
    return os.getenv("AWS_REGION", "us-east-1")


# ============================================================================
# KUBERNETES FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def kubernetes_client():
    """
    Kubernetes API client for test cluster.

    Returns:
        kubernetes.client.CoreV1Api: K8s API client

    Raises:
        pytest.skip: If Kubernetes is not available
    """
    try:
        from kubernetes import client, config

        # Try to load config (in-cluster or kubeconfig)
        try:
            config.load_incluster_config()
        except:
            config.load_kube_config()

        return client.CoreV1Api()
    except Exception as e:
        pytest.skip(f"Kubernetes not available: {e}")


@pytest.fixture(scope="function")
def clean_namespace(kubernetes_client, test_namespace) -> Generator[str, None, None]:
    """
    Create and cleanup a Kubernetes namespace for testing.

    Creates a namespace before test, deletes it after.
    Use this for tests that need isolated K8s resources.

    Args:
        kubernetes_client: K8s API client
        test_namespace: Base namespace name

    Yields:
        str: Namespace name to use

    Example:
        def test_deployment(clean_namespace):
            # deploy to clean_namespace
            # namespace is automatically cleaned up after test
    """
    from kubernetes import client

    # Create namespace
    namespace = f"{test_namespace}-{uuid.uuid4().hex[:6]}"

    try:
        kubernetes_client.create_namespace(body=client.V1Namespace(metadata=client.V1ObjectMeta(name=namespace)))
        logger.info(f"Created test namespace: {namespace}")

        yield namespace

    finally:
        # Cleanup namespace
        try:
            kubernetes_client.delete_namespace(name=namespace, body=client.V1DeleteOptions())
            logger.info(f"Deleted test namespace: {namespace}")
        except Exception as e:
            logger.warning(f"Failed to delete namespace {namespace}: {e}")


# ============================================================================
# JENKINS FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def jenkins_url() -> str:
    """
    Jenkins server URL.

    Returns:
        str: Jenkins URL from env or default
    """
    return os.getenv("JENKINS_URL", "http://jenkins.fawkes-platform.svc:8080")


@pytest.fixture(scope="session")
def jenkins_client(jenkins_url):
    """
    Jenkins API client.

    Returns:
        jenkinsapi.jenkins.Jenkins: Authenticated Jenkins client

    Raises:
        pytest.skip: If Jenkins is not available
    """
    try:
        from jenkinsapi.jenkins import Jenkins

        username = os.getenv("JENKINS_USER", "robot-account")
        token = os.getenv("JENKINS_TOKEN")

        if not token:
            pytest.skip("JENKINS_TOKEN not set")

        client = Jenkins(jenkins_url, username=username, password=token)

        # Verify connection
        client.get_version()

        return client
    except Exception as e:
        pytest.skip(f"Jenkins not available: {e}")


# ============================================================================
# GITHUB FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def github_token() -> str:
    """
    GitHub API token.

    Returns:
        str: GitHub token from environment

    Raises:
        pytest.skip: If token not available
    """
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        pytest.skip("GITHUB_TOKEN not set")
    return token


@pytest.fixture(scope="session")
def github_client(github_token):
    """
    GitHub API client.

    Returns:
        github.Github: Authenticated GitHub client

    Raises:
        pytest.skip: If GitHub is not available
    """
    try:
        from github import Github

        client = Github(github_token)

        # Verify authentication
        client.get_user().login

        return client
    except Exception as e:
        pytest.skip(f"GitHub not available: {e}")


# ============================================================================
# ARGOCD FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def argocd_url() -> str:
    """
    ArgoCD server URL.

    Returns:
        str: ArgoCD URL from env or default
    """
    return os.getenv("ARGOCD_URL", "http://argocd-server.argocd.svc")


@pytest.fixture(scope="session")
def argocd_token() -> str:
    """
    ArgoCD authentication token.

    Returns:
        str: ArgoCD token from environment

    Raises:
        pytest.skip: If token not available
    """
    token = os.getenv("ARGOCD_TOKEN")
    if not token:
        pytest.skip("ARGOCD_TOKEN not set")
    return token


# ============================================================================
# DORA METRICS FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def dora_metrics_url() -> str:
    """
    DORA metrics service URL.

    Returns:
        str: DORA metrics API URL
    """
    return os.getenv("DORA_METRICS_URL", "http://dora-metrics.fawkes-platform.svc:8080")


@pytest.fixture(scope="function")
def dora_metrics_client(dora_metrics_url):
    """
    DORA metrics API client.

    Returns:
        DORAMetricsClient: Client for recording metrics
    """

    class DORAMetricsClient:
        """Simple client for DORA metrics API."""

        def __init__(self, base_url: str):
            self.base_url = base_url
            self._commit_times = {}

        def record_commit(self, repo: str, sha: str, timestamp: datetime):
            """Record a commit for lead time calculation."""
            self._commit_times[f"{repo}/{sha}"] = timestamp
            logger.info(f"Recorded commit {sha} in {repo}")

        def get_commit_time(self, repo: str, sha: str = None) -> datetime:
            """Get recorded commit time."""
            if sha:
                return self._commit_times.get(f"{repo}/{sha}")
            # Return most recent for repo
            repo_commits = {k: v for k, v in self._commit_times.items() if k.startswith(f"{repo}/")}
            if repo_commits:
                return max(repo_commits.values())
            return datetime.utcnow()

        def record_deployment(self, service: str, version: str, status: str):
            """Record a deployment event."""
            import requests

            try:
                response = requests.post(
                    f"{self.base_url}/api/v1/deployments",
                    json={
                        "service": service,
                        "version": version,
                        "environment": "test",
                        "commit_sha": version,
                        "commit_timestamp": datetime.utcnow().isoformat(),
                        "deployment_timestamp": datetime.utcnow().isoformat(),
                        "status": status,
                    },
                    timeout=5,
                )
                logger.info(f"Recorded deployment: {service} {version} - {status}")
                return response.status_code == 201
            except Exception as e:
                logger.warning(f"Failed to record deployment: {e}")
                return False

        def record_failure(self, service: str, failure_type: str = "test_failure"):
            """Record a failure event."""
            logger.info(f"Recorded failure: {service} - {failure_type}")

    return DORAMetricsClient(dora_metrics_url)


# ============================================================================
# GIT FIXTURES
# ============================================================================


@pytest.fixture(scope="function")
def git_repo(tmp_path):
    """
    Create a temporary Git repository for testing.

    Args:
        tmp_path: pytest's tmp_path fixture

    Returns:
        git.Repo: Temporary Git repository

    Example:
        def test_commit(git_repo):
            # Make changes
            (git_repo.working_dir / "file.txt").write_text("content")
            git_repo.index.add(["file.txt"])
            git_repo.index.commit("test commit")
    """
    try:
        import git

        # Initialize repo
        repo = git.Repo.init(tmp_path)

        # Configure
        repo.config_writer().set_value("user", "name", "Test User").release()
        repo.config_writer().set_value("user", "email", "test@fawkes.local").release()

        # Initial commit
        (tmp_path / "README.md").write_text("# Test Repo")
        repo.index.add(["README.md"])
        repo.index.commit("Initial commit")

        return repo
    except ImportError:
        pytest.skip("GitPython not installed")


# ============================================================================
# MATTERMOST FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def mattermost_webhook_url() -> str:
    """
    Mattermost incoming webhook URL.

    Returns:
        str: Webhook URL from env or default
    """
    return os.getenv("MATTERMOST_WEBHOOK_URL", "http://mattermost.fawkes-platform.svc:8065/hooks/test")


@pytest.fixture(scope="function")
def mattermost_client(mattermost_webhook_url):
    """
    Simple Mattermost client for testing notifications.

    Returns:
        MattermostClient: Client for sending test messages
    """

    class MattermostClient:
        """Simple client for Mattermost webhooks."""

        def __init__(self, webhook_url: str):
            self.webhook_url = webhook_url

        def send_message(self, text: str, color: str = "good") -> bool:
            """Send a message to Mattermost."""
            import requests

            try:
                response = requests.post(
                    self.webhook_url, json={"text": text, "attachments": [{"color": color, "text": text}]}, timeout=5
                )
                return response.status_code == 200
            except Exception as e:
                logger.warning(f"Failed to send Mattermost message: {e}")
                return False

    return MattermostClient(mattermost_webhook_url)


# ============================================================================
# DATABASE FIXTURES
# ============================================================================


@pytest.fixture(scope="session")
def postgres_connection_string() -> str:
    """
    PostgreSQL connection string for testing.

    Returns:
        str: Connection string
    """
    return os.getenv("POSTGRES_CONNECTION", "postgresql://postgres:test@localhost:5432/fawkes_test")


@pytest.fixture(scope="function")
def clean_database(postgres_connection_string):
    """
    Provide a clean database for testing.

    Creates tables before test, drops them after.

    Yields:
        sqlalchemy.engine.Engine: Database engine
    """
    try:
        from sqlalchemy import create_engine, MetaData

        engine = create_engine(postgres_connection_string)
        metadata = MetaData()

        # Create all tables
        metadata.create_all(engine)

        yield engine

        # Drop all tables
        metadata.drop_all(engine)

    except ImportError:
        pytest.skip("SQLAlchemy not installed")
    except Exception as e:
        pytest.skip(f"Database not available: {e}")


# ============================================================================
# UTILITY FIXTURES
# ============================================================================


@pytest.fixture
def wait_for_condition():
    """
    Utility for waiting for a condition to be true.

    Returns:
        Callable: Function that waits for condition

    Example:
        def test_deployment(wait_for_condition):
            wait_for_condition(
                lambda: pod_is_ready(),
                timeout=300,
                interval=5,
                error_message="Pod never became ready"
            )
    """
    import time

    def _wait(condition_fn, timeout=60, interval=1, error_message="Timeout"):
        """
        Wait for condition_fn to return True.

        Args:
            condition_fn: Callable that returns bool
            timeout: Maximum seconds to wait
            interval: Seconds between checks
            error_message: Error message if timeout

        Raises:
            TimeoutError: If condition not met within timeout
        """
        start_time = time.time()

        while time.time() - start_time < timeout:
            try:
                if condition_fn():
                    return
            except Exception as e:
                logger.debug(f"Condition check failed: {e}")

            time.sleep(interval)

        raise TimeoutError(f"{error_message} (waited {timeout}s)")

    return _wait


@pytest.fixture
def capture_logs():
    """
    Capture logs during test execution.

    Returns:
        list: List of log records

    Example:
        def test_something(capture_logs):
            # do something that logs
            assert any("expected message" in record.message
                      for record in capture_logs)
    """
    import logging

    records = []

    class ListHandler(logging.Handler):
        def emit(self, record):
            records.append(record)

    handler = ListHandler()
    logger.addHandler(handler)

    yield records

    logger.removeHandler(handler)


# ============================================================================
# MARKER SHORTCUTS
# ============================================================================

# Convenience markers for common combinations
smoke = pytest.mark.smoke
slow = pytest.mark.slow
security = pytest.mark.security
