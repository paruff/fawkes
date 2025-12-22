"""Unit tests for main FastAPI application."""
import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from datetime import datetime


@pytest.mark.asyncio
async def test_health_endpoint():
    """Test health endpoint."""
    from fastapi.testclient import TestClient
    
    # Mock the lifespan to avoid actual startup
    with patch('app.main.lifespan'):
        from app.main import app
        client = TestClient(app)
        
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data['status'] == 'UP'
        assert data['service'] == 'anomaly-detection'


@pytest.mark.asyncio
async def test_root_endpoint():
    """Test root endpoint."""
    from fastapi.testclient import TestClient
    
    with patch('app.main.lifespan'):
        from app.main import app
        client = TestClient(app)
        
        response = client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        assert data['service'] == 'anomaly-detection'
        assert data['status'] == 'running'


@pytest.mark.asyncio
async def test_get_anomalies():
    """Test get anomalies endpoint."""
    from fastapi.testclient import TestClient
    from app.main import AnomalyScore, AnomalyDetection
    
    with patch('app.main.lifespan'):
        from app.main import app, recent_anomalies
        
        # Add test anomaly
        anomaly_score = AnomalyScore(
            metric="test_metric",
            timestamp=datetime.now(),
            score=0.85,
            confidence=0.9,
            value=500.0,
            expected_value=100.0,
            severity="high"
        )
        
        anomaly_detection = AnomalyDetection(
            id="test-123",
            anomaly=anomaly_score,
            detected_at=datetime.now(),
            alerted=False
        )
        
        recent_anomalies.insert(0, anomaly_detection)
        
        client = TestClient(app)
        response = client.get("/api/v1/anomalies")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) > 0
        assert data[0]['id'] == 'test-123'


@pytest.mark.asyncio
async def test_get_anomalies_with_filters():
    """Test get anomalies with filters."""
    from fastapi.testclient import TestClient
    from app.main import AnomalyScore, AnomalyDetection
    
    with patch('app.main.lifespan'):
        from app.main import app, recent_anomalies
        
        # Clear and add test anomalies
        recent_anomalies.clear()
        
        for i, severity in enumerate(['critical', 'high', 'medium']):
            anomaly_score = AnomalyScore(
                metric=f"test_metric_{i}",
                timestamp=datetime.now(),
                score=0.85,
                confidence=0.9,
                value=500.0,
                expected_value=100.0,
                severity=severity
            )
            
            anomaly_detection = AnomalyDetection(
                id=f"test-{i}",
                anomaly=anomaly_score,
                detected_at=datetime.now(),
                alerted=False
            )
            
            recent_anomalies.insert(0, anomaly_detection)
        
        client = TestClient(app)
        
        # Test severity filter
        response = client.get("/api/v1/anomalies?severity=critical")
        assert response.status_code == 200
        data = response.json()
        assert all(a['anomaly']['severity'] == 'critical' for a in data)
        
        # Test metric filter
        response = client.get("/api/v1/anomalies?metric=test_metric_0")
        assert response.status_code == 200
        data = response.json()
        assert all(a['anomaly']['metric'] == 'test_metric_0' for a in data)


@pytest.mark.asyncio
async def test_get_anomaly_by_id():
    """Test get specific anomaly by ID."""
    from fastapi.testclient import TestClient
    from app.main import AnomalyScore, AnomalyDetection
    
    with patch('app.main.lifespan'):
        from app.main import app, recent_anomalies
        
        recent_anomalies.clear()
        
        anomaly_score = AnomalyScore(
            metric="test_metric",
            timestamp=datetime.now(),
            score=0.85,
            confidence=0.9,
            value=500.0,
            expected_value=100.0,
            severity="high"
        )
        
        anomaly_detection = AnomalyDetection(
            id="test-specific",
            anomaly=anomaly_score,
            detected_at=datetime.now(),
            alerted=False
        )
        
        recent_anomalies.insert(0, anomaly_detection)
        
        client = TestClient(app)
        
        # Test getting existing anomaly
        response = client.get("/api/v1/anomalies/test-specific")
        assert response.status_code == 200
        data = response.json()
        assert data['id'] == 'test-specific'
        
        # Test getting non-existent anomaly
        response = client.get("/api/v1/anomalies/non-existent")
        assert response.status_code == 404


@pytest.mark.asyncio
async def test_get_stats():
    """Test get statistics endpoint."""
    from fastapi.testclient import TestClient
    from app.main import AnomalyScore, AnomalyDetection
    
    with patch('app.main.lifespan'):
        from app.main import app, recent_anomalies
        
        recent_anomalies.clear()
        
        # Add test anomalies
        for i in range(5):
            anomaly_score = AnomalyScore(
                metric=f"test_metric_{i}",
                timestamp=datetime.now(),
                score=0.85,
                confidence=0.9,
                value=500.0,
                expected_value=100.0,
                severity="high" if i % 2 == 0 else "medium"
            )
            
            anomaly_detection = AnomalyDetection(
                id=f"test-{i}",
                anomaly=anomaly_score,
                detected_at=datetime.now(),
                alerted=(i % 3 == 0)
            )
            
            recent_anomalies.insert(0, anomaly_detection)
        
        client = TestClient(app)
        response = client.get("/stats")
        
        assert response.status_code == 200
        data = response.json()
        assert data['total_anomalies'] == 5
        assert 'severity_counts' in data
        assert 'alerts_sent' in data


@pytest.mark.asyncio
async def test_get_models():
    """Test get models endpoint."""
    from fastapi.testclient import TestClient
    
    with patch('app.main.lifespan'):
        from app.main import app
        
        # Mock the detector module
        with patch('app.main.detector') as mock_detector:
            mock_detector.models_initialized = True
            mock_detector.get_model_info.return_value = [
                {'name': 'Test Model', 'type': 'test', 'description': 'Test'}
            ]
            
            client = TestClient(app)
            response = client.get("/api/v1/models")
            
            assert response.status_code == 200
            data = response.json()
            assert data['models_loaded'] is True
            assert len(data['models']) > 0
