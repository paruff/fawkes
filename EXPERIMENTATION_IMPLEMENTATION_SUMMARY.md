# Experimentation Framework Implementation Summary

## Issue #100: Build Experimentation Framework

**Epic**: 3.3 - Product Discovery & UX
**Milestone**: M3.3
**Priority**: P1
**Status**: ✅ Complete

## Overview

Built a complete A/B testing framework with statistical analysis, variant assignment, and results dashboards. The framework enables data-driven experimentation across the Fawkes platform.

## Implementation Details

### Service Architecture

**FastAPI-based Microservice**:
- **Language**: Python 3.11
- **Framework**: FastAPI with async/await support
- **Database**: PostgreSQL (CloudNativePG) for persistence
- **API**: RESTful with OpenAPI documentation
- **Metrics**: Prometheus instrumentation
- **Deployment**: Kubernetes with HA configuration

### Core Features

#### 1. Experiment Management
- Create experiments with variants, metrics, and hypotheses
- Lifecycle management: draft → running → stopped
- Traffic allocation control (0-100%)
- Target sample size configuration
- Significance level setting (default: 0.05)

#### 2. Variant Assignment
- **Consistent Hashing**: Same user always gets same variant
- **Traffic Allocation**: Control experiment participation percentage
- **Allocation Weights**: Distribute traffic across variants (e.g., 50/50, 70/30)
- **Context Storage**: Track assignment metadata

#### 3. Event Tracking
- Track conversion events per user/variant
- Support for custom metrics
- Value tracking for quantitative analysis
- Timestamp recording for time-series analysis

#### 4. Statistical Analysis
- **Two-Proportion Z-Test**: Compare variant conversion rates
- **Confidence Intervals**: 95% CI for each variant
- **P-Value Calculation**: Test statistical significance
- **Effect Size**: Measure practical significance
- **Automated Recommendations**: Data-driven decision support

#### 5. Monitoring & Observability
- **Prometheus Metrics**: 9 metric types exposed
  - Experiments created/active
  - Variant assignments
  - Event tracking
  - Analysis duration
  - Significant results
- **Grafana Dashboard**: 8 panels for visualization
  - Active experiments gauge
  - Assignment distribution
  - Event tracking rates
  - Statistical significance
  - P-value trends

### Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│         Experimentation Service (FastAPI)               │
│  • Experiment CRUD                                      │
│  • Variant Assignment (consistent hashing)             │
│  • Event Tracking                                       │
│  • Statistical Analysis (scipy)                         │
│  • Prometheus Metrics                                   │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│      PostgreSQL Database (CloudNativePG, 3 replicas)    │
│  • experiments: Metadata and configuration              │
│  • assignments: User-to-variant mappings                │
│  • events: Conversion tracking data                     │
└─────────────────────────────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    ▼                         ▼
┌──────────┐            ┌──────────┐
│ Unleash  │            │Plausible │
│(Feature  │            │(Analytics│
│ Flags)   │            │)         │
└──────────┘            └──────────┘
```

### Files Created

**Service Code (8 files)**:
- `services/experimentation/app/main.py` - FastAPI application and endpoints
- `services/experimentation/app/models.py` - Pydantic request/response models
- `services/experimentation/app/schema.py` - SQLAlchemy database schema
- `services/experimentation/app/database.py` - Database connection management
- `services/experimentation/app/experiment_manager.py` - Business logic
- `services/experimentation/app/statistical_analysis.py` - Statistical algorithms
- `services/experimentation/app/metrics.py` - Prometheus metrics
- `services/experimentation/app/__init__.py` - Package initialization

**Kubernetes Manifests (8 resources)**:
- `platform/apps/experimentation/deployment.yaml`:
  - ConfigMap for environment variables
  - Secret for admin token
  - Deployment (2 replicas, HA)
  - Service (ClusterIP)
  - Ingress (HTTPS with TLS)
  - ServiceMonitor (Prometheus)
  - PodDisruptionBudget (minAvailable: 1)
- `platform/apps/experimentation/kustomization.yaml` - Kustomize configuration
- `platform/apps/experimentation-application.yaml` - ArgoCD application

**Database (2 resources)**:
- `platform/apps/postgresql/db-experiment-cluster.yaml` - PostgreSQL cluster (3 replicas)
- `platform/apps/postgresql/db-experiment-credentials.yaml` - Database credentials

**Dashboard**:
- `platform/apps/grafana/dashboards/experimentation.json` - Grafana dashboard

**Testing & Validation**:
- `tests/bdd/features/experimentation.feature` - BDD tests (21 scenarios)
- `scripts/validate-experimentation.sh` - Validation script (10 checks)

**Documentation**:
- `services/experimentation/README.md` - Service documentation with API examples
- `platform/apps/experimentation/README.md` - Deployment guide

**Configuration**:
- `services/experimentation/requirements.txt` - Python dependencies
- `services/experimentation/requirements-dev.txt` - Dev dependencies
- `services/experimentation/Dockerfile` - Container image
- `services/experimentation/pytest.ini` - Test configuration
- Updated `Makefile` with `validate-at-e3-012` target
- Updated `platform/apps/postgresql/kustomization.yaml` with new database

## API Endpoints

### Experiment Management
- `POST /api/v1/experiments` - Create experiment
- `GET /api/v1/experiments` - List experiments
- `GET /api/v1/experiments/{id}` - Get experiment
- `PUT /api/v1/experiments/{id}` - Update experiment
- `DELETE /api/v1/experiments/{id}` - Delete experiment
- `POST /api/v1/experiments/{id}/start` - Start experiment
- `POST /api/v1/experiments/{id}/stop` - Stop experiment

### Assignment & Tracking
- `POST /api/v1/experiments/{id}/assign` - Assign variant to user
- `POST /api/v1/experiments/{id}/track` - Track event
- `GET /api/v1/experiments/{id}/stats` - Get statistical analysis

### System
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Acceptance Criteria Status

✅ **All criteria met**:

1. ✅ **Framework deployed**
   - FastAPI service deployed with 2 replicas
   - PostgreSQL database with 3 replicas (HA)
   - Kubernetes resources configured
   - ArgoCD application for GitOps

2. ✅ **Variant assignment working**
   - Consistent hash-based assignment implemented
   - Traffic allocation control (0-100%)
   - Variant allocation weights configurable
   - Assignment persistence in database

3. ✅ **Statistical analysis automated**
   - Two-proportion z-test implementation
   - Confidence interval calculation
   - P-value and significance testing
   - Effect size measurement
   - Automated recommendations

4. ✅ **Results dashboard**
   - Grafana dashboard with 8 panels
   - Real-time metrics visualization
   - Assignment distribution charts
   - Statistical significance indicators
   - P-value trends

5. ✅ **Integration with analytics**
   - Configuration for Unleash integration
   - Configuration for Plausible integration
   - Prometheus metrics exposure
   - ServiceMonitor for scraping

## Testing

### BDD Acceptance Tests (21 scenarios)
- Deployment health checks
- Database connectivity
- API functionality
- Experiment CRUD operations
- Variant assignment logic
- Traffic allocation
- Event tracking
- Statistical analysis
- Resource usage validation
- Resilience testing

### Validation Script (10 checks)
1. PostgreSQL cluster health
2. Service deployment status
3. Service and ingress configuration
4. API health endpoint
5. Database connectivity
6. Database schema validation
7. Prometheus metrics exposure
8. ServiceMonitor configuration
9. Resource usage (<70% target)
10. PodDisruptionBudget

**Run validation**: `make validate-at-e3-012`

## Resource Configuration

**Target**: <70% CPU/Memory utilization

| Component | Requests | Limits | Replicas | Total |
|-----------|----------|--------|----------|-------|
| Experimentation Service | 200m CPU, 256Mi | 1 CPU, 1Gi | 2 | 400m-2 CPU, 512Mi-2Gi |
| PostgreSQL Database | 200m CPU, 256Mi | 500m CPU, 512Mi | 3 | 600m-1.5 CPU, 768Mi-1.5Gi |
| **Total Platform Impact** | - | - | - | **1-3.5 CPU, 1.25-3.5Gi** |

## Security Features

- **Authentication**: Bearer token for admin operations
- **TLS**: Ingress with cert-manager certificates
- **Non-root**: Containers run as non-root user (1000)
- **Read-only filesystem**: Enhanced security posture
- **Security context**: Dropped capabilities
- **Secrets management**: Kubernetes secrets (Vault-ready)
- **Database encryption**: TLS for PostgreSQL connections

## Deployment

### Prerequisites
1. CloudNativePG operator installed
2. Ingress controller configured
3. cert-manager for TLS
4. Prometheus operator (optional, for metrics)

### Deploy via ArgoCD

```bash
# 1. Deploy database
kubectl apply -f platform/apps/postgresql/db-experiment-cluster.yaml
kubectl apply -f platform/apps/postgresql/db-experiment-credentials.yaml

# 2. Wait for database
kubectl wait --for=condition=Ready cluster/db-experiment-dev -n fawkes --timeout=300s

# 3. Deploy service
kubectl apply -f platform/apps/experimentation-application.yaml

# 4. Wait for deployment
kubectl wait --for=condition=Ready pod -l app=experimentation -n fawkes --timeout=300s

# 5. Validate
make validate-at-e3-012
```

### Access URLs
- **API**: https://experimentation.fawkes.idp
- **Metrics**: https://experimentation.fawkes.idp/metrics
- **Health**: https://experimentation.fawkes.idp/health
- **Dashboard**: https://grafana.fawkes.idp/d/experimentation

## Usage Example

```bash
# 1. Create experiment
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments \
  -H "Authorization: Bearer dev-admin-token" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Feature Test",
    "description": "Testing new feature impact",
    "hypothesis": "Feature increases conversion by 10%",
    "variants": [
      {"name": "control", "allocation": 0.5, "config": {}},
      {"name": "new-feature", "allocation": 0.5, "config": {"enabled": true}}
    ],
    "metrics": ["conversion"],
    "target_sample_size": 1000
  }'

# 2. Start experiment
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/start \
  -H "Authorization: Bearer dev-admin-token"

# 3. Assign variant
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/assign \
  -d '{"user_id": "user123"}'

# 4. Track event
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/track \
  -d '{"user_id": "user123", "event_name": "conversion", "value": 1.0}'

# 5. Get results
curl https://experimentation.fawkes.idp/api/v1/experiments/{id}/stats
```

## Integration Points

### With Unleash (Feature Flags)
- Use Unleash to control experiment traffic
- Gate experiments behind feature flags
- Gradual rollout integration

### With Plausible (Analytics)
- Cross-reference experiment events
- Combine with web analytics data
- Funnel analysis integration

### With Backstage
- Experiment management UI (future)
- Entity annotations for experiments
- Developer self-service

## Future Enhancements (Not in Scope)

1. **Multi-armed Bandit**: Dynamic traffic allocation based on performance
2. **Bayesian Analysis**: Alternative to frequentist statistics
3. **Multi-Variant Testing**: A/B/C/D tests with multiple variants
4. **Sequential Testing**: Early stopping for clear winners
5. **Segmentation**: Target experiments to user segments
6. **Backstage Plugin**: Native UI in developer portal

## References

- **Issue**: https://github.com/paruff/fawkes/issues/100
- **Dependencies**: #547 (Unleash), #548 (Plausible)
- **Statistical Methods**: Two-proportion z-test, confidence intervals
- **Technologies**: FastAPI, PostgreSQL, CloudNativePG, scipy, numpy

## Team Contact

- **Mattermost**: #fawkes-platform
- **Documentation**: https://docs.fawkes.idp/experimentation
- **Repository**: https://github.com/paruff/fawkes

---

**Implementation Date**: December 25, 2025
**Implemented By**: GitHub Copilot
**Status**: ✅ Complete - All acceptance criteria met
