"""
Continuous anomaly detection module.

This module runs background tasks to continuously query Prometheus,
detect anomalies using ML models, and trigger alerts.
"""
import asyncio
import logging
import os
from datetime import datetime, timedelta
from typing import List
import uuid

logger = logging.getLogger(__name__)

PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://prometheus-kube-prometheus-prometheus.fawkes.svc:9090")
DETECTION_INTERVAL_SECONDS = int(os.getenv("DETECTION_INTERVAL_SECONDS", "60"))
ALERTMANAGER_URL = os.getenv("ALERTMANAGER_URL", "http://prometheus-kube-prometheus-alertmanager.fawkes.svc:9093")
CONFIDENCE_LOW_THRESHOLD = float(os.getenv("CONFIDENCE_LOW_THRESHOLD", "0.7"))


async def run_continuous_detection():
    """
    Main loop for continuous anomaly detection.

    Queries Prometheus for metrics, applies ML models to detect anomalies,
    and triggers alerts when anomalies are detected.
    """
    logger.info(f"Starting continuous anomaly detection (interval: {DETECTION_INTERVAL_SECONDS}s)")

    from .main import http_client, recent_anomalies, ANOMALIES_DETECTED, FALSE_POSITIVE_RATE_GAUGE
    from .models import detector

    while True:
        try:
            start_time = datetime.now()

            # Query Prometheus for metrics to monitor
            metrics_to_check = [
                # Deployment failures (error rate spikes)
                'rate(http_requests_total{status=~"5.."}[5m])',
                # Build time anomalies
                'jenkins_job_duration_seconds',
                # Resource usage spikes (CPU)
                'rate(container_cpu_usage_seconds_total[5m])',
                # Resource usage spikes (Memory)
                'container_memory_usage_bytes',
                # API latency increases
                'http_request_duration_seconds',
                # Log error rate spikes
                'rate(log_messages_total{level="error"}[5m])',
            ]

            detected_anomalies = []

            for metric_query in metrics_to_check:
                try:
                    anomalies = await detector.detect_anomalies(metric_query, http_client)
                    if anomalies:
                        detected_anomalies.extend(anomalies)
                        logger.info(f"Detected {len(anomalies)} anomalies for query: {metric_query}")
                except Exception as e:
                    logger.error(f"Error detecting anomalies for {metric_query}: {e}")

            # Process detected anomalies
            for anomaly_score in detected_anomalies:
                from .main import AnomalyDetection

                anomaly_detection = AnomalyDetection(
                    id=str(uuid.uuid4()),
                    anomaly=anomaly_score,
                    detected_at=datetime.now(),
                    alerted=False
                )

                # Add to recent anomalies
                recent_anomalies.insert(0, anomaly_detection)
                if len(recent_anomalies) > 100:  # Keep only last 100
                    recent_anomalies.pop()

                # Track metrics
                ANOMALIES_DETECTED.labels(
                    metric=anomaly_score.metric,
                    severity=anomaly_score.severity
                ).inc()

                # Send alert if severity is high or critical
                if anomaly_score.severity in ['critical', 'high']:
                    try:
                        await send_alert(anomaly_detection, http_client)
                        anomaly_detection.alerted = True
                    except Exception as e:
                        logger.error(f"Failed to send alert: {e}")

                # Trigger RCA for critical anomalies
                if anomaly_score.severity == 'critical':
                    try:
                        from . import rca as rca_module
                        await rca_module.perform_root_cause_analysis(
                            anomaly_detection,
                            recent_anomalies
                        )
                    except Exception as e:
                        logger.error(f"Failed to perform RCA: {e}")

            # Update false positive rate estimate
            if len(recent_anomalies) > 10:
                # Simple heuristic: anomalies with low confidence are likely false positives
                low_confidence = sum(1 for a in recent_anomalies[:50] if a.anomaly.confidence < CONFIDENCE_LOW_THRESHOLD)
                fp_rate = low_confidence / min(50, len(recent_anomalies))
                FALSE_POSITIVE_RATE_GAUGE.set(fp_rate)

            duration = (datetime.now() - start_time).total_seconds()
            logger.debug(f"Detection cycle completed in {duration:.2f}s")

            # Wait for next interval
            await asyncio.sleep(DETECTION_INTERVAL_SECONDS)

        except asyncio.CancelledError:
            logger.info("Continuous detection cancelled")
            break
        except Exception as e:
            logger.error(f"Error in continuous detection loop: {e}", exc_info=True)
            await asyncio.sleep(DETECTION_INTERVAL_SECONDS)


async def send_alert(anomaly_detection, http_client):
    """
    Send alert to Alertmanager.

    Args:
        anomaly_detection: AnomalyDetection object
        http_client: HTTP client for sending requests
    """
    anomaly = anomaly_detection.anomaly

    alert = {
        "labels": {
            "alertname": "AnomalyDetected",
            "severity": anomaly.severity,
            "metric": anomaly.metric,
            "anomaly_id": anomaly_detection.id,
        },
        "annotations": {
            "summary": f"Anomaly detected in {anomaly.metric}",
            "description": (
                f"Anomaly detected: {anomaly.metric}\n"
                f"Score: {anomaly.score:.2f}\n"
                f"Confidence: {anomaly.confidence:.2%}\n"
                f"Expected: {anomaly.expected_value:.2f}\n"
                f"Actual: {anomaly.value:.2f}\n"
            ),
        },
        "startsAt": anomaly.timestamp.isoformat(),
    }

    try:
        response = await http_client.post(
            f"{ALERTMANAGER_URL}/api/v2/alerts",
            json=[alert],
            timeout=10.0
        )

        if response.status_code in [200, 202]:
            logger.info(f"Alert sent for anomaly {anomaly_detection.id}")
        else:
            logger.warning(f"Alert response status: {response.status_code}")

    except Exception as e:
        logger.error(f"Failed to send alert: {e}")
        raise
