# ADR-032: Product Analytics Platform Selection

**Status**: Accepted  
**Date**: 2025-12-25  
**Decision Makers**: Platform Team  
**Tags**: analytics, observability, privacy, gdpr

## Context

The Fawkes platform needs product analytics capabilities to:
- Track platform usage and feature adoption
- Understand user behavior and pain points
- Make data-driven decisions about platform improvements
- Measure impact of platform changes
- Support continuous discovery processes

Key requirements:
1. **Privacy-first**: GDPR compliant, no unnecessary data collection
2. **Cookie-less**: No consent banners needed
3. **Lightweight**: Minimal performance impact
4. **Self-hosted**: Data sovereignty, no third-party dependencies
5. **Developer-friendly**: Easy to instrument and use
6. **Resource-efficient**: Fits within platform resource constraints

## Decision

We will use **Plausible Analytics** as the product analytics platform.

## Options Considered

### 1. Plausible Analytics ⭐ (Selected)

**Pros:**
- ✅ Privacy-first by design, GDPR compliant out-of-box
- ✅ Cookie-less tracking, no consent banners needed
- ✅ Lightweight script (< 1KB vs 20KB+ for alternatives)
- ✅ Simple, clean UI focused on actionable metrics
- ✅ Open source, self-hosted, no vendor lock-in
- ✅ Low resource footprint (~500m CPU, ~1Gi RAM total)
- ✅ Custom events support for feature tracking
- ✅ Real-time dashboard with live visitor count
- ✅ Modern tech stack (Elixir, ClickHouse, PostgreSQL)
- ✅ Active development and community

**Cons:**
- ⚠️ Less feature-rich than Matomo (intentionally simpler)
- ⚠️ No built-in A/B testing (can be added separately)
- ⚠️ Newer project (less mature than Matomo)

**Resource Requirements:**
- Plausible: 200m CPU, 256Mi RAM (2 replicas)
- ClickHouse: 200m CPU, 256Mi RAM
- PostgreSQL: 200m CPU, 256Mi RAM (3 replicas)
- **Total**: ~800m CPU, ~1Gi RAM

### 2. Matomo (formerly Piwik)

**Pros:**
- ✅ Feature-rich with extensive analytics capabilities
- ✅ Mature project with large community
- ✅ Self-hosted, GDPR compliant with configuration
- ✅ Plugin ecosystem for extensions
- ✅ Built-in A/B testing, heatmaps, session recording

**Cons:**
- ❌ Heavier tracking script (20KB+ vs 1KB)
- ❌ More complex setup and configuration
- ❌ Requires more resources (~2-4GB RAM minimum)
- ❌ Cookie-based by default (requires config for cookie-less)
- ❌ More complex UI with many features we don't need
- ❌ PHP-based (additional runtime to maintain)

**Resource Requirements:**
- Matomo: 1 CPU, 2Gi RAM minimum (plus PHP-FPM, nginx)
- MySQL/MariaDB: 500m CPU, 1Gi RAM
- Redis: 100m CPU, 256Mi RAM
- **Total**: ~2 CPU, ~3.5Gi RAM

### 3. Google Analytics

**Pros:**
- ✅ Free, no infrastructure to maintain
- ✅ Feature-rich with advanced analytics
- ✅ Large ecosystem of integrations

**Cons:**
- ❌ Not self-hosted, data sent to Google
- ❌ Privacy concerns, GDPR compliance issues
- ❌ Cookie-based, requires consent banners
- ❌ Blocked by many ad blockers
- ❌ Terms of Service concerns for internal tools
- ❌ Against platform philosophy of self-sovereignty

### 4. Umami Analytics

**Pros:**
- ✅ Privacy-focused, GDPR compliant
- ✅ Lightweight and simple
- ✅ Self-hosted, open source
- ✅ Modern tech stack (Next.js, PostgreSQL)

**Cons:**
- ❌ Less mature than Plausible
- ❌ Smaller community
- ❌ Fewer features than Plausible
- ❌ Less active development

### 5. PostHog

**Pros:**
- ✅ Comprehensive product analytics platform
- ✅ Session recording, feature flags, A/B testing
- ✅ Self-hosted option available
- ✅ Modern architecture

**Cons:**
- ❌ Heavy resource requirements (4GB+ RAM)
- ❌ Complex setup and maintenance
- ❌ Over-featured for our current needs
- ❌ Cookie-based by default
- ❌ Enterprise features require paid license

## Decision Rationale

We selected **Plausible** for the following reasons:

### 1. Privacy & Compliance
Plausible is privacy-first by design, requiring no configuration to be GDPR compliant. This aligns with our platform values and reduces legal/compliance overhead.

### 2. Performance Impact
With a < 1KB script size, Plausible has minimal impact on page load times. This is critical for maintaining excellent developer experience on Backstage and other platform UIs.

### 3. Resource Efficiency
Total resource footprint (~800m CPU, ~1Gi RAM) fits comfortably within our 70% resource utilization target. Matomo would require 2-3x more resources.

### 4. Simplicity
Plausible's focused feature set matches our needs without unnecessary complexity. We need core metrics (page views, events, sources) not advanced features like heatmaps or session recording.

### 5. Developer Experience
- Simple instrumentation (one script tag)
- Clean API for custom events
- Easy-to-understand dashboard
- No complex configuration needed

### 6. Architecture Fit
- Uses PostgreSQL (already deployed via CloudNativePG)
- Uses ClickHouse (purpose-built for time-series analytics)
- Stateless application layer (easy to scale)
- Cloud-native deployment model

### 7. Future-Proof
- Active open source community
- Regular releases and security updates
- Growing ecosystem
- Self-hosted = no vendor lock-in

## Implementation

See [Product Analytics Implementation Guide](../implementation-plan/product-analytics-implementation.md) for details.

Key components:
- Plausible v2.0 (2 replicas for HA)
- ClickHouse v23.3 (analytics data)
- PostgreSQL v16.4 (metadata, via CloudNativePG)
- Ingress with TLS (https://plausible.fawkes.idp)

Instrumentation:
- Backstage: Configured in app-config.yaml
- Custom events: Deploy, Create, View, Run actions
- API proxy: Available at /plausible/api

## Consequences

### Positive
- ✅ Fast deployment (< 5 minutes)
- ✅ Low operational overhead
- ✅ Privacy-compliant by default
- ✅ Minimal resource impact
- ✅ Clean, actionable insights
- ✅ No consent banners needed
- ✅ Data sovereignty maintained

### Negative
- ⚠️ Limited advanced features (heatmaps, session recording)
- ⚠️ No built-in A/B testing (can add separate tool)
- ⚠️ Smaller community than Matomo/GA

### Neutral
- ℹ️ Need to self-manage updates and backups
- ℹ️ Custom features require code changes
- ℹ️ Learning curve for team (though minimal)

## Alternatives for Specific Use Cases

If advanced features are needed in the future:

- **A/B Testing**: Add Unleash or GrowthBook
- **Session Recording**: Add OpenReplay or Highlight
- **Heatmaps**: Add Hotjar (if privacy concerns addressed) or self-hosted alternative
- **Funnel Analysis**: Extend Plausible with custom queries or add PostHog

## Validation

Acceptance criteria validation: [AT-E3-011](../../scripts/validate-product-analytics.sh)

BDD tests: [tests/bdd/features/product-analytics.feature](../../tests/bdd/features/product-analytics.feature)

## References

- [Plausible Documentation](https://plausible.io/docs)
- [Plausible vs Matomo Comparison](https://plausible.io/vs-matomo)
- [GDPR Compliance](https://plausible.io/data-policy)
- [Self-Hosting Guide](https://plausible.io/docs/self-hosting)
- [Issue #97](https://github.com/paruff/fawkes/issues/97)

## Review & Approval

- **Proposed**: 2025-12-25
- **Reviewed**: Pending
- **Approved**: Pending
- **Implemented**: 2025-12-25
