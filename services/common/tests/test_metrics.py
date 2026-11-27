from fastapi import FastAPI
from fastapi.testclient import TestClient
from fawkes_common.metrics import add_metrics_route
from prometheus_client import CONTENT_TYPE_LATEST, Counter

EXAMPLE = Counter("fawkes_common_test_events", "Counter used by this test")


def test_metrics_route_serves_the_registry_without_a_redirect():
    app = FastAPI()
    add_metrics_route(app)
    EXAMPLE.inc()

    response = TestClient(app).get("/metrics", follow_redirects=False)

    assert response.status_code == 200
    assert response.headers["content-type"] == CONTENT_TYPE_LATEST
    assert "fawkes_common_test_events_total 1.0" in response.text
