from dataclasses import dataclass
from datetime import datetime
import requests

@dataclass
class DORAMetric:
    metric_type: str
    value: float
    timestamp: datetime
    test_name: str
    tags: list

class DORAMetricsCollector:
    """Collect DORA metrics from test runs"""
    
    def __init__(self, api_url: str):
        self.api_url = api_url
    
    def record_deployment(self, duration: float, success: bool):
        """Record deployment for frequency and lead time"""
        metric = DORAMetric(
            metric_type='deployment',
            value=duration,
            timestamp=datetime.utcnow(),
            test_name='automated_test',
            tags=['success' if success else 'failure']
        )
        self._send_metric(metric)
    
    def record_recovery(self, duration: float):
        """Record time to recover from failure"""
        metric = DORAMetric(
            metric_type='mttr',
            value=duration,
            timestamp=datetime.utcnow(),
            test_name='recovery_test',
            tags=['recovery']
        )
        self._send_metric(metric)
    
    def _send_metric(self, metric: DORAMetric):
        """Send metric to collection endpoint"""
        requests.post(
            f"{self.api_url}/metrics",
            json={
                'type': metric.metric_type,
                'value': metric.value,
                'timestamp': metric.timestamp.isoformat(),
                'test': metric.test_name,
                'tags': metric.tags
            }
        )