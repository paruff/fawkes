# ADR-033: Feature Flags Platform with Unleash and OpenFeature

**Status**: Accepted
**Date**: 2025-12-25
**Decision Makers**: Platform Team
**Tags**: feature-flags, unleash, openfeature, experimentation, a-b-testing

## Context

The Fawkes platform needs feature flag management capabilities to:
- Enable gradual rollouts of new features (reduce blast radius)
- Support A/B testing and experimentation
- Provide kill switches for emergency feature disablement
- Allow targeted feature releases (by team, environment, user)
- Facilitate continuous delivery with reduced risk
- Support trunk-based development practices

Key requirements:
1. **Self-hosted**: Data sovereignty, no third-party dependencies
2. **Open Source**: Community-driven, transparent, no vendor lock-in
3. **Vendor-agnostic API**: Ability to swap providers without code changes
4. **Developer-friendly**: Easy to instrument and use across languages
5. **Resource-efficient**: Fits within platform resource constraints (<70% utilization)
6. **GitOps-compatible**: Declarative configuration, version-controlled
7. **Audit trail**: Complete history of flag changes for compliance

## Decision

We will deploy **Unleash** as the feature flag management platform with **OpenFeature** as the standardized client API layer.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  (Backstage, Python services, Go services, etc.)            │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  OpenFeature SDK Layer                       │
│   Vendor-agnostic API (CNCF standard)                       │
│   Consistent interface across TypeScript, Python, Go, etc.  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│               Unleash Provider Backend                       │
│   Feature flag management, evaluation, strategies           │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL (CloudNativePG)                      │
│   Feature flags, strategies, audit logs                     │
└─────────────────────────────────────────────────────────────┘
```

## Options Considered

### 1. Unleash + OpenFeature ⭐ (Selected)

**Pros:**
- ✅ Mature open-source project with active community
- ✅ Self-hosted, full control over data
- ✅ Comprehensive UI for flag management
- ✅ Advanced rollout strategies (gradual, targeting, custom)
- ✅ OpenFeature provider available (vendor independence)
- ✅ Multi-environment support (dev, staging, prod)
- ✅ API tokens for CI/CD integration
- ✅ Audit logging built-in
- ✅ Uses PostgreSQL (already deployed via CloudNativePG)
- ✅ Low resource footprint (~400m CPU, ~512Mi RAM total)
- ✅ SDKs for all major languages
- ✅ Prometheus metrics support

**Cons:**
- ⚠️ Requires PostgreSQL database (acceptable - already deployed)
- ⚠️ Additional component to maintain

**Resource Requirements:**
- Unleash: 200m CPU, 256Mi RAM (2 replicas)
- PostgreSQL: 200m CPU, 256Mi RAM (3 replicas HA)
- **Total**: ~1 CPU, ~1.5Gi RAM

### 2. LaunchDarkly

**Pros:**
- ✅ Feature-rich commercial product
- ✅ Excellent UI/UX
- ✅ Strong experimentation features
- ✅ OpenFeature provider available

**Cons:**
- ❌ SaaS-only, no self-hosted option
- ❌ Expensive pricing ($8.33/seat/month minimum)
- ❌ Data sovereignty concerns
- ❌ Vendor lock-in despite OpenFeature
- ❌ Against platform philosophy

### 3. Flagsmith

**Pros:**
- ✅ Open source with self-hosted option
- ✅ Modern UI
- ✅ OpenFeature compatible

**Cons:**
- ❌ Less mature than Unleash
- ❌ Smaller community
- ❌ More resource-intensive (requires Redis, Postgres, and app server)
- ❌ Limited rollout strategies compared to Unleash

### 4. GrowthBook

**Pros:**
- ✅ Open source
- ✅ A/B testing focus
- ✅ Statistical analysis built-in

**Cons:**
- ❌ Primarily an experimentation platform, not feature flags
- ❌ No official OpenFeature provider
- ❌ More complex setup
- ❌ Heavier resource requirements

### 5. Feature Flags in Application Code

**Pros:**
- ✅ No external dependencies
- ✅ Full control

**Cons:**
- ❌ No centralized management UI
- ❌ Requires code changes to update flags
- ❌ No audit trail
- ❌ No gradual rollout capabilities
- ❌ Poor developer experience

## Decision Rationale

### 1. Unleash as the Backend

**Maturity & Reliability:**
- Battle-tested in production by thousands of companies
- Active development and security updates
- Proven track record for stability

**Feature Set:**
- **Standard Strategy**: Simple on/off toggles
- **Gradual Rollout**: Percentage-based rollouts (e.g., 25% of users)
- **User IDs**: Target specific users or teams
- **Flexible Rollout**: Combine constraints (environment + team + custom)
- **Variants**: A/B testing with multiple variations
- **Custom Strategies**: Extend via API

**Self-Hosted Benefits:**
- Data sovereignty (all data stays in Fawkes cluster)
- No vendor fees
- Full control over upgrades and configuration
- Integration with existing PostgreSQL infrastructure

**Resource Efficiency:**
- Lightweight Node.js application (~200m CPU, 256Mi RAM per pod)
- Fits within 70% resource utilization target
- Scales horizontally with replicas

### 2. OpenFeature as the Client API

**Vendor Independence:**
- CNCF incubating project (vendor-neutral governance)
- Standardized API across all providers
- Freedom to switch providers without code changes

**Multi-Language Support:**
- Official SDKs: TypeScript, Python, Go, Java, .NET, PHP, Ruby
- Community SDKs: Rust, Swift, Elixir
- Consistent API across all languages

**Future-Proof:**
- CNCF backing ensures long-term standardization
- Growing ecosystem of providers
- Easy migration path if requirements change

**Developer Experience:**
- Simple, intuitive API
- Language-idiomatic implementations
- Well-documented with examples

### 3. Combined Benefits

**Best of Both Worlds:**
- Unleash provides powerful management capabilities
- OpenFeature provides code-level abstraction
- Can replace Unleash without changing application code

**Alignment with Fawkes Principles:**
- **Cloud-Agnostic**: OpenFeature provides abstraction layer
- **Extensible**: Can add new providers via OpenFeature
- **Observable**: Prometheus metrics from Unleash
- **Secure**: Self-hosted, no data leaves cluster
- **GitOps-Driven**: Unleash config can be version-controlled

## Implementation

### Deployment Components

**PostgreSQL Database:**
```yaml
# CloudNativePG Cluster: db-unleash-dev
instances: 3  # HA configuration
storage: 10Gi
resources:
  requests: 200m CPU, 256Mi RAM
  limits: 500m CPU, 512Mi RAM
```

**Unleash Server:**
```yaml
# Deployment: unleash
replicas: 2  # HA configuration
image: unleashorg/unleash-server:5.11
resources:
  requests: 200m CPU, 256Mi RAM
  limits: 1 CPU, 1Gi RAM
```

**Access:**
- UI: `https://unleash.fawkes.idp`
- API: `https://unleash.fawkes.idp/api`
- Ingress: TLS via cert-manager

### Application Integration

**Backstage (TypeScript):**
```typescript
import { OpenFeature } from '@openfeature/server-sdk';
import { UnleashProvider } from '@openfeature/unleash-provider';

await OpenFeature.setProviderAndWait(
  new UnleashProvider({
    url: 'https://unleash.fawkes.idp/api',
    appName: 'backstage',
    apiToken: process.env.UNLEASH_API_TOKEN
  })
);

const client = OpenFeature.getClient();
const enabled = await client.getBooleanValue('new-feature', false);
```

**Python Services:**
```python
from openfeature import api
from openfeature.contrib.provider.unleash import UnleashProvider

api.set_provider(UnleashProvider(
    url="https://unleash.fawkes.idp/api",
    app_name="python-service",
    api_token=os.getenv("UNLEASH_API_TOKEN")
))

client = api.get_client()
enabled = client.get_boolean_value("new-feature", False)
```

**Go Services:**
```go
import (
    "github.com/open-feature/go-sdk/openfeature"
    unleash "github.com/open-feature/go-sdk-contrib/providers/unleash/pkg"
)

openfeature.SetProvider(unleash.NewProvider(
    unleash.WithURL("https://unleash.fawkes.idp/api"),
    unleash.WithAppName("go-service"),
    unleash.WithAPIToken(os.Getenv("UNLEASH_API_TOKEN")),
))

client := openfeature.NewClient("my-app")
enabled, _ := client.BooleanValue(ctx, "new-feature", false, openfeature.EvaluationContext{})
```

## Consequences

### Positive

✅ **Risk Reduction**: Gradual rollouts minimize blast radius of new features
✅ **Faster Delivery**: Ship features behind flags, enable progressively
✅ **Experimentation**: A/B testing without separate infrastructure
✅ **Emergency Response**: Kill switches for quick feature disablement
✅ **Targeted Releases**: Roll out to specific teams or users first
✅ **Trunk-Based Development**: Merge incomplete features safely
✅ **No Vendor Lock-in**: OpenFeature allows provider swapping
✅ **Low Operational Overhead**: Self-hosted, uses existing PostgreSQL
✅ **Audit Compliance**: Complete history of flag changes

### Negative

⚠️ **Additional Complexity**: Another platform component to maintain
⚠️ **Learning Curve**: Teams need to learn feature flag best practices
⚠️ **Flag Debt**: Unused flags accumulate if not cleaned up regularly
⚠️ **Testing Overhead**: Need to test both flag states

### Neutral

ℹ️ **Database Dependency**: Requires PostgreSQL (already deployed)
ℹ️ **Network Hop**: Adds latency for flag evaluations (cached by SDKs)
ℹ️ **Secret Management**: API tokens need secure distribution

## Mitigation Strategies

### Flag Debt Prevention
- Document flag lifecycle in flag description
- Set expiration dates for temporary flags
- Quarterly flag cleanup reviews
- Automated alerts for old flags (>6 months)

### Performance Optimization
- SDK-side caching (OpenFeature supports this)
- Short-lived flags evaluated at startup, not per-request
- Use local evaluation where possible

### Testing Strategy
- Unit tests for both flag states
- Integration tests with flag variations
- Feature flag configuration in test fixtures

## Monitoring & Observability

### Metrics (Prometheus)
- `unleash_feature_toggles_total` - Total feature flags
- `unleash_client_requests_total` - API request count
- `unleash_db_pool_*` - Database connection pool metrics

### Dashboards (Grafana)
- Feature flag usage over time
- API request rates and latencies
- Flag evaluation counts per application

### Alerts
- Unleash pod not ready
- Database connection failures
- High API error rates

## Migration Path (Future)

If we need to migrate to a different provider:

1. **Deploy New Provider** alongside Unleash
2. **Configure OpenFeature** with new provider
3. **Test Flag Evaluations** match between providers
4. **Switch Provider** in OpenFeature configuration (no code changes!)
5. **Verify Application Behavior** unchanged
6. **Decommission Unleash** after migration period

## Validation

**Acceptance Criteria:** [AT-E3-006](../../tests/bdd/features/feature-flags-unleash.feature)

**Validation Script:** [scripts/validate-at-e3-006.sh](../../scripts/validate-at-e3-006.sh)

**BDD Tests:** [tests/bdd/features/feature-flags-unleash.feature](../../tests/bdd/features/feature-flags-unleash.feature)

## References

- [Unleash Documentation](https://docs.getunleash.io/)
- [OpenFeature Documentation](https://openfeature.dev/)
- [OpenFeature Providers](https://openfeature.dev/ecosystem)
  - [Unleash Provider (JavaScript/TypeScript)](https://github.com/open-feature/js-sdk-contrib/tree/main/libs/providers/unleash)
  - [Unleash Provider (Python)](https://github.com/open-feature/python-sdk-contrib/tree/main/providers/unleash)
  - [Unleash Provider (Go)](https://github.com/open-feature/go-sdk-contrib/tree/main/providers/unleash)
- [CNCF OpenFeature Project](https://www.cncf.io/projects/openfeature/)
- [Feature Flags Best Practices](https://www.unleash-hosted.com/articles/feature-flag-best-practices)
- [Issue #99: Deploy Feature Flags Platform](https://github.com/paruff/fawkes/issues/99)
- [ADR-032: Product Analytics Platform Selection](./ADR-032%20Product%20Analytics%20Platform%20Selection.md)

## Review & Approval

- **Proposed**: 2025-12-25
- **Reviewed**: Pending
- **Approved**: Pending
- **Implemented**: 2025-12-25
