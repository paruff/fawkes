"""
Root Cause Analysis (RCA) Module.

This module performs root cause analysis when anomalies are detected by:
1. Collecting context (recent deployments, config changes)
2. Querying logs for errors
3. Checking correlated metrics
4. Using LLM to suggest likely root causes
5. Providing remediation suggestions and runbook links
"""
import logging
import os
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import httpx

logger = logging.getLogger(__name__)

# Configuration
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
LLM_API_URL = os.getenv("LLM_API_URL", "https://api.openai.com/v1/chat/completions")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4")
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://prometheus-kube-prometheus-prometheus.fawkes.svc:9090")
LOKI_URL = os.getenv("LOKI_URL", "http://loki.fawkes.svc:3100")
ARGOCD_URL = os.getenv("ARGOCD_URL", "http://argocd-server.fawkes.svc:80")


async def perform_root_cause_analysis(anomaly_detection, recent_anomalies: List):
    """
    Perform comprehensive root cause analysis for an anomaly.

    Args:
        anomaly_detection: AnomalyDetection object
        recent_anomalies: List of recent anomaly detections for correlation
    """
    from .main import RootCause, ROOT_CAUSE_ANALYSES, http_client

    logger.info(f"Starting RCA for anomaly {anomaly_detection.id}")

    try:
        anomaly = anomaly_detection.anomaly

        # 1. Collect recent events (deployments, config changes)
        recent_events = await _collect_recent_events(anomaly.timestamp, http_client)

        # 2. Query logs for errors around the anomaly time
        log_errors = await _query_error_logs(anomaly.timestamp, anomaly.metric, http_client)

        # 3. Check for correlated metrics
        correlated_metrics = await _find_correlated_metrics(anomaly, recent_anomalies, http_client)

        # 4. Use LLM to generate root cause suggestions
        likely_causes, remediation_suggestions = await _generate_llm_suggestions(
            anomaly, recent_events, log_errors, correlated_metrics, http_client
        )

        # 5. Find relevant runbooks
        runbook_links = _find_runbooks(anomaly)

        # Create RootCause object
        root_cause = RootCause(
            anomaly_id=anomaly_detection.id,
            likely_causes=likely_causes,
            correlated_metrics=correlated_metrics,
            recent_events=recent_events,
            remediation_suggestions=remediation_suggestions,
            runbook_links=runbook_links,
        )

        # Attach to anomaly detection
        anomaly_detection.root_cause = root_cause

        ROOT_CAUSE_ANALYSES.labels(status="success").inc()
        logger.info(f"RCA completed for anomaly {anomaly_detection.id}")

    except Exception as e:
        logger.error(f"Failed to perform RCA for anomaly {anomaly_detection.id}: {e}", exc_info=True)
        ROOT_CAUSE_ANALYSES.labels(status="error").inc()


async def _collect_recent_events(timestamp: datetime, http_client) -> List[str]:
    """
    Collect recent events like deployments and config changes.

    Args:
        timestamp: Anomaly timestamp
        http_client: HTTP client

    Returns:
        List of event descriptions
    """
    events = []

    try:
        # Look back 30 minutes before the anomaly
        lookback = timestamp - timedelta(minutes=30)

        # Query Prometheus for deployment events
        # This is a simplified version - in production, you'd query ArgoCD or K8s events
        query = "changes(kube_deployment_status_replicas_updated[30m])"

        params = {"query": query, "time": timestamp.timestamp()}

        response = await http_client.get(f"{PROMETHEUS_URL}/api/v1/query", params=params, timeout=10.0)

        if response.status_code == 200:
            data = response.json()
            results = data.get("data", {}).get("result", [])

            for result in results:
                metric = result.get("metric", {})
                deployment = metric.get("deployment", "unknown")
                namespace = metric.get("namespace", "unknown")
                value = result.get("value", [None, 0])[1]

                if float(value) > 0:
                    events.append(f"Deployment update: {namespace}/{deployment}")

        # Add some common event patterns
        if not events:
            events.append("No recent deployments detected")

    except Exception as e:
        logger.error(f"Error collecting recent events: {e}")
        events.append(f"Error collecting events: {str(e)}")

    return events[:5]  # Return top 5 events


async def _query_error_logs(timestamp: datetime, metric: str, http_client) -> List[str]:
    """
    Query logs for errors around the anomaly time.

    Args:
        timestamp: Anomaly timestamp
        metric: Metric name for context
        http_client: HTTP client

    Returns:
        List of error log entries
    """
    errors = []

    try:
        # Query Loki for error logs (if available)
        # This is a simplified version

        # For now, return a placeholder
        errors.append("Log querying requires Loki integration (pending)")

        # In production, you would:
        # 1. Parse metric to extract relevant labels (namespace, pod, etc.)
        # 2. Query Loki with those labels
        # 3. Filter for error level logs
        # 4. Return recent errors around the timestamp

    except Exception as e:
        logger.error(f"Error querying logs: {e}")
        errors.append(f"Error querying logs: {str(e)}")

    return errors[:10]  # Return top 10 errors


async def _find_correlated_metrics(anomaly, recent_anomalies: List, http_client) -> List[str]:
    """
    Find metrics that show anomalies correlated with this one.

    Args:
        anomaly: AnomalyScore object
        recent_anomalies: List of recent anomalies
        http_client: HTTP client

    Returns:
        List of correlated metric names
    """
    correlated = []

    try:
        # Find anomalies within 5 minutes of this one
        time_window = timedelta(minutes=5)

        for other_detection in recent_anomalies:
            other_anomaly = other_detection.anomaly

            # Skip same metric
            if other_anomaly.metric == anomaly.metric:
                continue

            # Check if timestamps are close
            time_diff = abs((other_anomaly.timestamp - anomaly.timestamp).total_seconds())
            if time_diff <= time_window.total_seconds():
                correlated.append(other_anomaly.metric)

        # Deduplicate
        correlated = list(set(correlated))

    except Exception as e:
        logger.error(f"Error finding correlated metrics: {e}")

    return correlated[:5]  # Return top 5 correlated metrics


async def _generate_llm_suggestions(
    anomaly, recent_events: List[str], log_errors: List[str], correlated_metrics: List[str], http_client
) -> tuple[List[str], List[str]]:
    """
    Use LLM to generate root cause suggestions and remediation steps.

    Args:
        anomaly: AnomalyScore object
        recent_events: List of recent events
        log_errors: List of error logs
        correlated_metrics: List of correlated metrics
        http_client: HTTP client

    Returns:
        Tuple of (likely_causes, remediation_suggestions)
    """
    if not LLM_API_KEY:
        logger.warning("LLM API key not configured, using rule-based suggestions")
        return _generate_rule_based_suggestions(anomaly, recent_events, correlated_metrics)

    try:
        # Construct context for LLM
        context = f"""
Anomaly Detection Report:

Metric: {anomaly.metric}
Timestamp: {anomaly.timestamp}
Severity: {anomaly.severity}
Anomaly Score: {anomaly.score:.2f}
Confidence: {anomaly.confidence:.2%}
Expected Value: {anomaly.expected_value:.2f}
Actual Value: {anomaly.value:.2f}

Recent Events (last 30 minutes):
{chr(10).join(f"- {event}" for event in recent_events)}

Correlated Anomalies:
{chr(10).join(f"- {metric}" for metric in correlated_metrics) if correlated_metrics else "None detected"}

Error Logs:
{chr(10).join(f"- {error}" for error in log_errors[:3])}

Based on this information, provide:
1. Top 3 likely root causes
2. Top 3 remediation suggestions

Format your response as:
ROOT CAUSES:
1. [cause 1]
2. [cause 2]
3. [cause 3]

REMEDIATION:
1. [step 1]
2. [step 2]
3. [step 3]
"""

        # Call LLM API
        response = await http_client.post(
            LLM_API_URL,
            headers={"Authorization": f"Bearer {LLM_API_KEY}", "Content-Type": "application/json"},
            json={
                "model": LLM_MODEL,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert SRE analyzing system anomalies. Provide concise, actionable insights.",
                    },
                    {"role": "user", "content": context},
                ],
                "temperature": 0.7,
                "max_tokens": 500,
            },
            timeout=30.0,
        )

        if response.status_code == 200:
            data = response.json()
            content = data.get("choices", [{}])[0].get("message", {}).get("content", "")

            # Parse LLM response
            likely_causes, remediation = _parse_llm_response(content)

            if likely_causes and remediation:
                return likely_causes, remediation
        else:
            logger.warning(f"LLM API returned status {response.status_code}")

    except Exception as e:
        logger.error(f"Error calling LLM API: {e}")

    # Fall back to rule-based
    return _generate_rule_based_suggestions(anomaly, recent_events, correlated_metrics)


def _parse_llm_response(content: str) -> tuple[List[str], List[str]]:
    """Parse LLM response into causes and remediation lists."""
    causes = []
    remediation = []

    lines = content.strip().split("\n")
    current_section = None

    for line in lines:
        line = line.strip()

        if "ROOT CAUSES" in line.upper():
            current_section = "causes"
            continue
        elif "REMEDIATION" in line.upper():
            current_section = "remediation"
            continue

        # Parse numbered items
        if line and (line[0].isdigit() or line.startswith("-")):
            # Remove number/bullet and clean up
            text = line.lstrip("0123456789.-) ").strip()
            if text:
                if current_section == "causes":
                    causes.append(text)
                elif current_section == "remediation":
                    remediation.append(text)

    return causes[:3], remediation[:3]


def _generate_rule_based_suggestions(
    anomaly, recent_events: List[str], correlated_metrics: List[str]
) -> tuple[List[str], List[str]]:
    """
    Generate rule-based suggestions when LLM is not available.

    Args:
        anomaly: AnomalyScore object
        recent_events: List of recent events
        correlated_metrics: List of correlated metrics

    Returns:
        Tuple of (likely_causes, remediation_suggestions)
    """
    causes = []
    remediation = []

    metric_lower = anomaly.metric.lower()

    # Deployment-related
    if "error" in metric_lower or "5" in metric_lower:
        causes.append("Increased error rate detected - possible recent deployment issue")
        causes.append("Application bug or regression introduced")
        remediation.append("Review recent code changes and deployments")
        remediation.append("Check application logs for error details")
        remediation.append("Consider rolling back recent deployment if issue persists")

    # Resource-related
    if "cpu" in metric_lower or "memory" in metric_lower:
        causes.append("Resource exhaustion or memory leak")
        causes.append("Increased load or traffic spike")
        remediation.append("Check resource quotas and limits")
        remediation.append("Analyze application memory usage patterns")
        remediation.append("Scale up resources or optimize application")

    # Latency-related
    if "latency" in metric_lower or "duration" in metric_lower:
        causes.append("Downstream service degradation")
        causes.append("Database or cache performance issue")
        remediation.append("Check dependent services health")
        remediation.append("Review database query performance")
        remediation.append("Check for network issues")

    # Build-related
    if "jenkins" in metric_lower or "build" in metric_lower:
        causes.append("Build configuration change or dependency issue")
        causes.append("Test suite instability or new failing tests")
        remediation.append("Review recent build configuration changes")
        remediation.append("Check for new or updated dependencies")
        remediation.append("Analyze test failure patterns")

    # If we have recent events, add them as potential causes
    if recent_events and any("Deployment" in e for e in recent_events):
        if not any("deployment" in c.lower() for c in causes):
            causes.insert(0, f"Recent deployment detected: {recent_events[0]}")

    # If we have correlated metrics, mention them
    if correlated_metrics:
        causes.append(f"Correlated with anomalies in: {', '.join(correlated_metrics[:2])}")

    # Ensure we have at least 3 of each
    if len(causes) < 3:
        causes.append("System configuration change or environmental factor")
    if len(remediation) < 3:
        remediation.append("Monitor system for pattern recurrence")

    return causes[:3], remediation[:3]


def _find_runbooks(anomaly) -> List[str]:
    """
    Find relevant runbook links based on anomaly characteristics.

    Args:
        anomaly: AnomalyScore object

    Returns:
        List of runbook URLs or descriptions
    """
    runbooks = []

    metric_lower = anomaly.metric.lower()

    # Map metrics to runbooks
    if "error" in metric_lower or "5" in metric_lower:
        runbooks.append("Runbook: High Error Rate Investigation")
        runbooks.append("https://fawkes.example.com/runbooks/high-error-rate")

    if "cpu" in metric_lower or "memory" in metric_lower:
        runbooks.append("Runbook: Resource Exhaustion Response")
        runbooks.append("https://fawkes.example.com/runbooks/resource-exhaustion")

    if "latency" in metric_lower or "duration" in metric_lower:
        runbooks.append("Runbook: High Latency Troubleshooting")
        runbooks.append("https://fawkes.example.com/runbooks/high-latency")

    if "jenkins" in metric_lower or "build" in metric_lower:
        runbooks.append("Runbook: Build Failure Investigation")
        runbooks.append("https://fawkes.example.com/runbooks/build-failures")

    # General runbooks
    if not runbooks:
        runbooks.append("General Incident Response Runbook")
        runbooks.append("https://fawkes.example.com/runbooks/incident-response")

    return runbooks[:3]
