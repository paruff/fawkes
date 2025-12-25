"""Unit tests for SonarQube integration."""
import pytest
from unittest.mock import Mock, AsyncMock
import httpx


@pytest.fixture
def mock_http_client():
    """Mock HTTP client."""
    mock = Mock(spec=httpx.AsyncClient)
    return mock


@pytest.fixture
def sonarqube_integration(mock_http_client):
    """Create SonarQube integration instance."""
    from integrations.sonarqube import SonarQubeIntegration

    return SonarQubeIntegration(
        sonarqube_url="http://sonarqube.test:9000",
        sonarqube_token="test-token",
        http_client=mock_http_client
    )


@pytest.mark.asyncio
async def test_get_pr_findings_success(sonarqube_integration, mock_http_client):
    """Test fetching PR findings successfully."""
    # Mock successful response
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "issues": [
            {
                "key": "issue1",
                "component": "test:repo:src/main.py",
                "line": 42,
                "message": "Potential SQL injection",
                "severity": "CRITICAL",
                "type": "VULNERABILITY",
                "rule": "python:S3649"
            },
            {
                "key": "issue2",
                "component": "test:repo:src/utils.py",
                "line": 10,
                "message": "Remove this unused variable",
                "severity": "MINOR",
                "type": "CODE_SMELL",
                "rule": "python:S1481"
            }
        ]
    }

    mock_http_client.get = AsyncMock(return_value=mock_response)

    findings = await sonarqube_integration.get_pr_findings("test/repo", 123)

    assert len(findings) == 2
    assert findings[0]["severity"] == "critical"  # CRITICAL mapped
    assert findings[0]["category"] == "security"  # VULNERABILITY mapped
    assert findings[1]["severity"] == "medium"  # MINOR mapped
    assert findings[1]["category"] == "best_practices"  # CODE_SMELL mapped


@pytest.mark.asyncio
async def test_get_pr_findings_not_found(sonarqube_integration, mock_http_client):
    """Test handling of project not found."""
    mock_response = Mock()
    mock_response.status_code = 404

    mock_http_client.get = AsyncMock(return_value=mock_response)

    findings = await sonarqube_integration.get_pr_findings("test/repo", 123)

    assert findings == []


@pytest.mark.asyncio
async def test_get_pr_findings_no_token(mock_http_client):
    """Test handling when token not configured."""
    from integrations.sonarqube import SonarQubeIntegration

    integration = SonarQubeIntegration(
        sonarqube_url="http://sonarqube.test:9000",
        sonarqube_token="",
        http_client=mock_http_client
    )

    findings = await integration.get_pr_findings("test/repo", 123)

    assert findings == []


def test_standardize_findings(sonarqube_integration):
    """Test standardization of SonarQube findings."""
    raw_issues = [
        {
            "key": "issue1",
            "component": "project:key:src/main.py",
            "line": 42,
            "message": "SQL injection vulnerability",
            "severity": "BLOCKER",
            "type": "VULNERABILITY",
            "rule": "squid:S3649",
            "effort": "30min"
        },
        {
            "key": "issue2",
            "component": "project:key:src/util.py",
            "line": 10,
            "message": "Code smell",
            "severity": "MAJOR",
            "type": "CODE_SMELL",
            "rule": "squid:S1234"
        }
    ]

    standardized = sonarqube_integration._standardize_findings(raw_issues)

    assert len(standardized) == 2

    # Check first issue
    assert standardized[0]["file"] == "src/main.py"
    assert standardized[0]["line"] == 42
    assert standardized[0]["severity"] == "critical"
    assert standardized[0]["category"] == "security"
    assert standardized[0]["message"] == "SQL injection vulnerability"

    # Check second issue
    assert standardized[1]["file"] == "src/util.py"
    assert standardized[1]["line"] == 10
    assert standardized[1]["severity"] == "high"
    assert standardized[1]["category"] == "best_practices"


def test_prioritize_findings(sonarqube_integration):
    """Test prioritization of findings by severity and category."""
    findings = [
        {"severity": "low", "category": "documentation", "message": "Issue 1"},
        {"severity": "critical", "category": "security", "message": "Issue 2"},
        {"severity": "medium", "category": "quality", "message": "Issue 3"},
        {"severity": "high", "category": "security", "message": "Issue 4"},
    ]

    prioritized = sonarqube_integration._prioritize_findings(findings)

    # Critical security should be first
    assert prioritized[0]["message"] == "Issue 2"
    assert prioritized[0]["severity"] == "critical"

    # High security should be second
    assert prioritized[1]["message"] == "Issue 4"
    assert prioritized[1]["severity"] == "high"

    # Low priority should be last
    assert prioritized[-1]["message"] == "Issue 1"
    assert prioritized[-1]["severity"] == "low"


def test_deduplicate_with_ai_findings(sonarqube_integration):
    """Test deduplication between AI and SonarQube findings."""
    ai_findings = [
        {
            "path": "src/main.py",
            "line": 42,
            "category": "security",
            "message": "SQL injection detected"
        },
        {
            "path": "src/util.py",
            "line": 100,
            "category": "performance",
            "message": "Inefficient loop"
        }
    ]

    sq_findings = [
        {
            "file": "src/main.py",
            "line": 42,
            "category": "security",
            "message": "SQL injection vulnerability"
        },
        {
            "file": "src/helper.py",
            "line": 20,
            "category": "quality",
            "message": "Unused variable"
        }
    ]

    deduplicated = sonarqube_integration.deduplicate_with_ai_findings(
        ai_findings, sq_findings
    )

    # Should have 2 AI findings + 1 unique SQ finding = 3 total
    assert len(deduplicated) == 3

    # Check that duplicate SQ finding was removed
    # AI findings have 'path', SQ findings have 'file'
    main_py_count = sum(1 for f in deduplicated if f.get("path") == "src/main.py" or f.get("file") == "src/main.py")
    assert main_py_count == 1  # Only AI finding, SQ duplicate removed


@pytest.mark.asyncio
async def test_get_project_metrics_success(sonarqube_integration, mock_http_client):
    """Test fetching project metrics successfully."""
    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "component": {
            "measures": [
                {"metric": "bugs", "value": "5"},
                {"metric": "vulnerabilities", "value": "2"},
                {"metric": "code_smells", "value": "10"},
                {"metric": "coverage", "value": "75.5"}
            ]
        }
    }

    mock_http_client.get = AsyncMock(return_value=mock_response)

    metrics = await sonarqube_integration.get_project_metrics("test:project")

    assert metrics is not None
    assert metrics["bugs"] == "5"
    assert metrics["vulnerabilities"] == "2"
    assert metrics["coverage"] == "75.5"


@pytest.mark.asyncio
async def test_get_project_metrics_no_token(mock_http_client):
    """Test metrics fetch when token not configured."""
    from integrations.sonarqube import SonarQubeIntegration

    integration = SonarQubeIntegration(
        sonarqube_url="http://sonarqube.test:9000",
        sonarqube_token="",
        http_client=mock_http_client
    )

    metrics = await integration.get_project_metrics("test:project")

    assert metrics is None
