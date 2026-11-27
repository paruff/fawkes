from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)


def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "fawkes-telemetry-engine", "version": "0.1.0"}


def test_metrics_are_exposed():
    response = client.get("/metrics")

    assert response.status_code == 200
    assert "python_info" in response.text
