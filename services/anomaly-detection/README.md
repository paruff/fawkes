# Anomaly Detection Service

AI-powered anomaly detection for metrics, logs, and system behavior in the Fawkes platform.

## Overview

This service provides real-time anomaly detection for:
- Deployment failures (error rate spikes)
- Build time anomalies (unusually long builds)
- Resource usage spikes (CPU/memory)
- API latency increases
- Log error rate spikes

## Features

- **Multiple Detection Algorithms**: Isolation Forest, Z-score, IQR, Rate of Change
- **Root Cause Analysis**: Automatic RCA with LLM-powered suggestions
- **Low False Positives**: Target <5% false positive rate
- **Prometheus Integration**: Queries metrics from Prometheus
- **Alertmanager Integration**: Sends alerts for critical anomalies
- **REST API**: Query anomalies and trigger RCA

## Architecture

```
┌─────────────────┐
│   Prometheus    │◄──── Scrapes metrics
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  Anomaly Detection Service  │
│  ┌───────────────────────┐  │
│  │   ML Models           │  │
│  │  - Isolation Forest   │  │
│  │  - Statistical        │  │
│  │  - Time Series        │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │   Root Cause Analysis │  │
│  │  - Event correlation  │  │
│  │  - Log analysis       │  │
│  │  - LLM suggestions    │  │
│  └───────────────────────┘  │
└─────────────┬───────────────┘
              │
              ▼
       ┌──────────────┐
       │ Alertmanager │
       └──────────────┘
```

## API Endpoints

### Health and Status

- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /metrics` - Prometheus metrics
- `GET /stats` - Detection statistics

### Anomalies

- `GET /api/v1/anomalies` - List recent anomalies
  - Query params: `limit`, `severity`, `metric`
- `GET /api/v1/anomalies/{id}` - Get specific anomaly
- `POST /api/v1/anomalies/{id}/rca` - Trigger RCA for anomaly

### Models

- `GET /api/v1/models` - Get loaded ML models info

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PROMETHEUS_URL` | `http://prometheus-kube-prometheus-prometheus.fawkes.svc:9090` | Prometheus server URL |
| `ALERTMANAGER_URL` | `http://prometheus-kube-prometheus-alertmanager.fawkes.svc:9093` | Alertmanager URL |
| `LLM_API_KEY` | - | OpenAI API key for RCA |
| `LLM_API_URL` | `https://api.openai.com/v1/chat/completions` | LLM API endpoint |
| `LLM_MODEL` | `gpt-4` | LLM model to use |
| `FALSE_POSITIVE_THRESHOLD` | `0.05` | Target false positive rate (5%) |
| `DETECTION_INTERVAL_SECONDS` | `60` | Detection interval in seconds |
| `ANOMALY_THRESHOLD` | `0.7` | Anomaly score threshold (0-1) |
| `LOOKBACK_MINUTES` | `60` | Historical data lookback window |
| `MIN_SAMPLES` | `10` | Minimum samples required for detection |
| `ZSCORE_THRESHOLD` | `3.0` | Z-score threshold for statistical detection |
| `IQR_MULTIPLIER` | `1.5` | IQR multiplier for outlier detection |
| `CONFIDENCE_LOW_THRESHOLD` | `0.7` | Threshold below which anomalies are considered low confidence |

## Deployment

### Local Development

```bash
# Install dependencies
pip install -r requirements-dev.txt

# Run service
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker

```bash
# Build image
docker build -t anomaly-detection:latest .

# Run container
docker run -p 8000:8000 \
  -e PROMETHEUS_URL=http://prometheus:9090 \
  anomaly-detection:latest
```

### Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/deployment.yaml

# Check status
kubectl get pods -n fawkes -l app=anomaly-detection

# View logs
kubectl logs -n fawkes -l app=anomaly-detection -f
```

### ArgoCD

```bash
# Deploy via ArgoCD
kubectl apply -f ../platform/apps/anomaly-detection-application.yaml

# Check sync status
argocd app get anomaly-detection
```

## Usage Examples

### Get Recent Anomalies

```bash
curl http://anomaly-detection.local/api/v1/anomalies
```

### Filter by Severity

```bash
curl http://anomaly-detection.local/api/v1/anomalies?severity=critical
```

### Trigger Root Cause Analysis

```bash
curl -X POST http://anomaly-detection.local/api/v1/anomalies/{id}/rca
```

### Check Statistics

```bash
curl http://anomaly-detection.local/api/v1/stats
```

## Testing

### Unit Tests

```bash
pytest tests/unit -v
```

### Integration Tests

```bash
pytest tests/integration -v
```

### Chaos Testing

Inject test anomaly to verify detection:

```bash
# Inject high error rate
./tests/chaos/inject-high-error-rate.sh

# Verify detection within 5 minutes
curl http://anomaly-detection.local/api/v1/anomalies
```

## Metrics

The service exposes Prometheus metrics:

- `anomaly_detection_total{metric, severity}` - Total anomalies detected
- `anomaly_detection_duration_seconds` - Detection processing duration
- `anomaly_detection_false_positive_rate` - Estimated false positive rate
- `anomaly_detection_models_loaded` - Number of ML models loaded
- `anomaly_detection_rca_total{status}` - Total RCA performed

## Detection Algorithms

### 1. Isolation Forest
General-purpose anomaly detection using ensemble of isolation trees.
- Works well for multivariate data
- Low training time
- Good for detecting outliers

### 2. Statistical Z-Score
Detects points that deviate significantly from the mean.
- Fast and simple
- Works well for normally distributed data
- Threshold: |z-score| > 3

### 3. Interquartile Range (IQR)
Detects outliers using quartiles.
- Robust to outliers
- Works well for skewed distributions
- Threshold: Q1 - 1.5*IQR or Q3 + 1.5*IQR

### 4. Rate of Change
Detects sudden spikes or drops.
- Good for detecting rapid changes
- Works well for time series data
- Threshold: Rate of change z-score > 3

## Root Cause Analysis

When anomalies are detected, the system performs automatic RCA:

1. **Event Correlation**: Checks for recent deployments, config changes
2. **Log Analysis**: Queries error logs around anomaly time
3. **Metric Correlation**: Finds other metrics showing anomalies
4. **LLM Suggestions**: Uses LLM to generate likely causes and remediation
5. **Runbook Links**: Provides links to relevant runbooks

## False Positive Mitigation

Target: <5% false positive rate

Strategies:
- Multiple detection algorithms (consensus voting)
- Confidence scoring based on algorithm agreement
- Historical pattern learning
- Adaptive thresholds based on metric characteristics
- Manual feedback loop (future enhancement)

## Troubleshooting

### Service not starting

Check logs:
```bash
kubectl logs -n fawkes -l app=anomaly-detection
```

Common issues:
- Prometheus connection failed: Check PROMETHEUS_URL
- Models not loading: Check resource limits
- LLM API errors: Check LLM_API_KEY

### No anomalies detected

- Check that Prometheus has data: `curl $PROMETHEUS_URL/api/v1/status/config`
- Verify detection interval: Check DETECTION_INTERVAL_SECONDS
- Lower anomaly threshold: Adjust ANOMALY_THRESHOLD
- Increase lookback window: Adjust LOOKBACK_MINUTES

### High false positive rate

- Increase anomaly threshold: Set ANOMALY_THRESHOLD higher
- Require higher confidence: Filter by confidence score
- Adjust detection parameters: Tune MIN_SAMPLES, LOOKBACK_MINUTES

## Future Enhancements

- [ ] Prophet-based time series forecasting
- [ ] LSTM neural networks for complex patterns
- [ ] Feedback mechanism for false positives
- [ ] Multi-metric anomaly detection
- [ ] Anomaly severity auto-tuning
- [ ] Integration with incident management
- [ ] Historical anomaly database
- [ ] Custom detection rules via API

## References

- [Isolation Forest Paper](https://cs.nju.edu.cn/zhouzh/zhouzh.files/publication/icdm08b.pdf)
- [Prometheus API](https://prometheus.io/docs/prometheus/latest/querying/api/)
- [Anomaly Detection Best Practices](https://www.anodot.com/blog/anomaly-detection-best-practices/)

## License

See LICENSE file in repository root.
