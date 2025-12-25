# ADR-010: Ingress Controller for Service Access

## Status
Accepted

## Context

The Fawkes platform integrates multiple services that require external access:

**Core Services**:
- Backstage (Developer Portal & Dojo Hub) - Primary user interface
- Mattermost (Team Collaboration) - Chat and collaboration
- Focalboard (Project Management) - Kanban boards and planning
- ArgoCD (GitOps UI) - Deployment visualization
- Jenkins (CI/CD UI) - Pipeline management
- Grafana (Observability) - Metrics and dashboards
- Harbor (Container Registry UI) - Image management
- SonarQube (Code Quality) - Security and quality reports

**Access Requirements**:
- Single entry point with consistent domain structure
- TLS/SSL encryption for all services
- Path-based or subdomain-based routing
- Rate limiting and DDoS protection
- Authentication integration (OIDC/OAuth2)
- Certificate management automation
- Load balancing across replicas
- WebSocket support (Mattermost, ArgoCD, Jenkins)
- Health check integration
- Request/response logging for security auditing

**Technical Constraints**:
- Must work across AWS, Azure, GCP, and on-premises environments
- Should integrate with cert-manager for automated certificate provisioning
- Must support both path-based (/backstage) and subdomain-based (backstage.fawkes.example.com) routing
- Should minimize cloud provider lock-in
- Must support learner environments with dynamic provisioning
- Should provide observability (request metrics, tracing)

**Security Requirements**:
- Force HTTPS/TLS for all traffic
- Support for custom certificates and Let's Encrypt
- Web Application Firewall (WAF) capabilities
- Rate limiting per service and per IP
- DDoS protection
- Security headers (HSTS, CSP, X-Frame-Options)
- IP whitelisting capabilities for sensitive services

**Operational Requirements**:
- Easy configuration via annotations or CRDs
- Automatic service discovery
- Rolling updates without downtime
- Clear error pages and troubleshooting
- Integration with platform monitoring

## Decision

We will use **NGINX Ingress Controller** as the primary ingress solution for the Fawkes platform.

### Architecture

```
Internet
   |
   v
┌─────────────────────────────────────────┐
│  Cloud Load Balancer (AWS NLB/ALB)      │
│  (Optional, for production)              │
└─────────────────────────────────────────┘
   |
   v
┌─────────────────────────────────────────┐
│  NGINX Ingress Controller                │
│  - TLS Termination                       │
│  - Path/Subdomain Routing                │
│  - Rate Limiting                         │
│  - Authentication (OAuth2 Proxy)         │
└─────────────────────────────────────────┘
   |
   ├──> Backstage Service (/)
   ├──> Mattermost Service (/mattermost)
   ├──> Focalboard Service (/focalboard)
   ├──> ArgoCD Service (/argocd)
   ├──> Jenkins Service (/jenkins)
   ├──> Grafana Service (/grafana)
   ├──> Harbor Service (/harbor)
   └──> SonarQube Service (/sonarqube)
```

### Routing Strategy

**Primary: Subdomain-Based Routing** (Production)
```
https://backstage.fawkes.example.com  → Backstage
https://chat.fawkes.example.com       → Mattermost
https://boards.fawkes.example.com     → Focalboard
https://cd.fawkes.example.com         → ArgoCD
https://ci.fawkes.example.com         → Jenkins
https://metrics.fawkes.example.com    → Grafana
https://registry.fawkes.example.com   → Harbor
https://quality.fawkes.example.com    → SonarQube
```

**Alternative: Path-Based Routing** (Development/Learning)
```
https://fawkes.example.com/           → Backstage
https://fawkes.example.com/chat       → Mattermost
https://fawkes.example.com/boards     → Focalboard
https://fawkes.example.com/cd         → ArgoCD
https://fawkes.example.com/ci         → Jenkins
https://fawkes.example.com/metrics    → Grafana
https://fawkes.example.com/registry   → Harbor
https://fawkes.example.com/quality    → SonarQube
```

### Certificate Management

Integration with **cert-manager** for automated certificate provisioning:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: platform-team@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Example Ingress Configuration

**Backstage (Primary Portal)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backstage
  namespace: fawkes-core
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - backstage.fawkes.example.com
    secretName: backstage-tls
  rules:
  - host: backstage.fawkes.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backstage
            port:
              number: 7007
```

**Mattermost (WebSocket Support)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mattermost
  namespace: fawkes-collaboration
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
    nginx.ingress.kubernetes.io/websocket-services: "mattermost"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - chat.fawkes.example.com
    secretName: mattermost-tls
  rules:
  - host: chat.fawkes.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mattermost
            port:
              number: 8065
```

### Security Configuration

**Rate Limiting**:
```yaml
annotations:
  nginx.ingress.kubernetes.io/limit-rps: "10"
  nginx.ingress.kubernetes.io/limit-connections: "20"
```

**IP Whitelisting** (for admin services):
```yaml
annotations:
  nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,172.16.0.0/12"
```

**Security Headers**:
```yaml
annotations:
  nginx.ingress.kubernetes.io/configuration-snippet: |
    more_set_headers "X-Frame-Options: DENY";
    more_set_headers "X-Content-Type-Options: nosniff";
    more_set_headers "X-XSS-Protection: 1; mode=block";
    more_set_headers "Strict-Transport-Security: max-age=31536000; includeSubDomains";
```

### OAuth2 Proxy Integration

For services without native SSO support:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  annotations:
    nginx.ingress.kubernetes.io/auth-url: "https://oauth2.fawkes.example.com/oauth2/auth"
    nginx.ingress.kubernetes.io/auth-signin: "https://oauth2.fawkes.example.com/oauth2/start?rd=$escaped_request_uri"
```

### Monitoring Integration

NGINX Ingress Controller exposes Prometheus metrics:
- Request rate per service
- Request duration percentiles
- Error rates (4xx, 5xx)
- Bytes transferred
- Upstream response time

Grafana dashboards: **NGINX Ingress Controller** (official dashboard ID: 9614)

### Deployment Configuration

**NGINX Ingress Controller Helm Values**:
```yaml
controller:
  replicaCount: 3

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"

  metrics:
    enabled: true
    serviceMonitor:
      enabled: true

  config:
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    use-proxy-protocol: "false"
    enable-real-ip: "true"
    proxy-body-size: "50m"
    ssl-protocols: "TLSv1.2 TLSv1.3"
    ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"

  podAnnotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "10254"
```

## Consequences

### Positive

1. **Cloud Agnostic**: NGINX Ingress works identically across AWS, Azure, GCP, and on-premises
2. **Mature & Proven**: Battle-tested in production at massive scale, large community support
3. **Feature Rich**: Comprehensive feature set including rate limiting, WebSocket, authentication
4. **Observable**: Native Prometheus metrics integration
5. **Flexible Routing**: Supports both path-based and subdomain-based routing strategies
6. **Cost Effective**: Open source with no licensing costs
7. **Well Documented**: Extensive documentation, examples, and community resources
8. **Security Hardened**: Regular security updates, CVE tracking, hardening guides available
9. **GitOps Friendly**: Declarative YAML configuration fits ArgoCD workflow
10. **Learning Friendly**: Simple annotation-based configuration good for dojo learners

### Negative

1. **Resource Overhead**: NGINX controller pods consume cluster resources (mitigated by proper sizing)
2. **Single Point of Failure**: Requires 3+ replicas for high availability
3. **Configuration Complexity**: Advanced features require learning NGINX-specific annotations
4. **Path-Based Routing Limitations**: Some applications (like Mattermost) work better with subdomain routing
5. **Certificate Management Dependency**: Requires cert-manager for automated TLS (adds complexity)
6. **Reload on Configuration Change**: Configuration changes trigger NGINX reload (brief traffic disruption)

### Neutral

1. **Load Balancer Costs**: Cloud load balancers incur costs (AWS NLB ~$16/month + data transfer)
2. **Monitoring Overhead**: Requires Prometheus/Grafana for observability
3. **DNS Management**: Subdomain routing requires wildcard DNS or multiple A records
4. **Learning Curve**: Platform team must understand NGINX configuration paradigms

## Alternatives Considered

### Alternative 1: Traefik

**Pros**:
- Native Let's Encrypt integration (no cert-manager needed)
- Dynamic configuration via labels
- Built-in dashboard for traffic visualization
- Smaller resource footprint
- Excellent WebSocket support
- Modern, actively developed

**Cons**:
- Smaller community compared to NGINX
- Less enterprise adoption
- More limited advanced features (rate limiting, WAF)
- Documentation less comprehensive for complex scenarios
- Fewer third-party integrations

**Reason for Rejection**: While Traefik is excellent and modern, NGINX Ingress has broader enterprise adoption, more comprehensive documentation for complex scenarios, and better alignment with DORA best practices documentation. The larger community makes it easier for Fawkes learners to find troubleshooting resources.

### Alternative 2: Istio/Envoy Service Mesh

**Pros**:
- Full service mesh capabilities (mTLS, traffic management, observability)
- Advanced traffic routing (A/B testing, canary, circuit breaking)
- Superior observability (distributed tracing, detailed metrics)
- Built-in security (zero-trust networking)
- Envoy is modern, high-performance proxy

**Cons**:
- Significant complexity overhead (steep learning curve)
- High resource consumption (sidecar for every pod)
- Operational burden (control plane management, upgrades)
- Overkill for ingress-only use case
- Adds 6-8 weeks to MVP timeline
- Too complex for learner environments

**Reason for Rejection**: Service mesh capabilities are valuable but represent over-engineering for MVP. Fawkes needs ingress management, not full service mesh. Istio/Envoy can be considered post-MVP as "Advanced Networking" module in Brown Belt curriculum.

### Alternative 3: Kong Ingress Controller

**Pros**:
- API gateway features (rate limiting, authentication, transformation)
- Plugin ecosystem for extensibility
- Enterprise version available with support
- Good for API-heavy platforms
- Lua-based customization
- Built-in developer portal

**Cons**:
- More complex than pure ingress controller
- Requires PostgreSQL for production (additional dependency)
- Licensing considerations (enterprise features)
- Smaller community than NGINX
- API gateway features not needed for internal platform

**Reason for Rejection**: Kong's strength is API management, which is not a primary Fawkes requirement. The additional complexity and PostgreSQL dependency don't provide sufficient value for our use case. NGINX provides everything we need without API gateway overhead.

### Alternative 4: HAProxy Ingress

**Pros**:
- Extremely high performance and efficiency
- Very low resource consumption
- Battle-tested load balancing capabilities
- Excellent documentation
- Used by major internet properties

**Cons**:
- Smaller Kubernetes community compared to NGINX
- Less flexible annotation-based configuration
- Fewer examples and tutorials for Kubernetes
- Less integration with cloud-native ecosystem
- Limited WebSocket support compared to NGINX

**Reason for Rejection**: While HAProxy is excellent for performance-critical scenarios, NGINX Ingress provides better Kubernetes-native integration, more comprehensive documentation for learners, and broader community support. HAProxy's performance advantages are not critical for Fawkes' scale.

### Alternative 5: Cloud Provider Ingress (AWS ALB, GCP GCLB, Azure App Gateway)

**Pros**:
- Native cloud integration
- Managed service (no controller to maintain)
- Tight security integration (IAM, security groups)
- Automatic scaling
- Lower operational overhead

**Cons**:
- **Cloud vendor lock-in** (violates Fawkes portability principle)
- Inconsistent behavior across clouds
- Limited customization compared to NGINX
- Annotations differ per cloud
- Cannot run on-premises or in learner laptops
- Makes dojo lab provisioning cloud-specific

**Reason for Rejection**: Violates core Fawkes principle of cloud portability. Learners need consistent experience across environments. Platform teams should be able to deploy Fawkes anywhere, including on-premises or local Kubernetes clusters. Cloud ingress controllers prevent this flexibility.

### Alternative 6: Contour (Envoy-based)

**Pros**:
- Uses Envoy proxy (modern, high-performance)
- Simpler than full Istio deployment
- Good HTTPProxy CRD for advanced routing
- CNCF project with growing community
- Excellent for multi-tenancy

**Cons**:
- Smaller community and ecosystem than NGINX
- Less mature documentation
- Fewer examples and tutorials
- Less enterprise adoption
- Not as feature-complete for edge use cases

**Reason for Rejection**: While Contour is a good middle ground between NGINX and Istio, its smaller community and less mature documentation make it less suitable for a learning-focused platform. NGINX's extensive resources better support dojo learners troubleshooting issues independently.

## Implementation Plan

### Phase 1: MVP (Week 3 of Sprint 01)

1. **Deploy NGINX Ingress Controller** [4 hours]
   - Install via Helm chart
   - Configure for AWS NLB (or equivalent)
   - Verify controller pods running
   - Test basic HTTP routing

2. **Deploy cert-manager** [2 hours]
   - Install cert-manager via Helm
   - Create ClusterIssuer for Let's Encrypt staging
   - Test certificate provisioning
   - Create production ClusterIssuer

3. **Create Ingress for Backstage** [2 hours]
   - Subdomain-based routing (backstage.fawkes.dev)
   - TLS certificate from Let's Encrypt
   - Force HTTPS redirect
   - Test end-to-end access

4. **Document Standard Ingress Pattern** [2 hours]
   - Create ingress template for new services
   - Document annotation patterns
   - Create troubleshooting guide
   - Add to Dojo Module 2 curriculum

### Phase 2: Core Services (Weeks 4-5)

5. **Deploy Ingress for Collaboration Services** [4 hours]
   - Mattermost with WebSocket support
   - Focalboard (integrated with Mattermost)
   - Test real-time features

6. **Deploy Ingress for CI/CD Services** [4 hours]
   - Jenkins with authentication
   - ArgoCD with SSO
   - Harbor with rate limiting

7. **Deploy Ingress for Observability Services** [3 hours]
   - Grafana with OAuth2 proxy
   - Prometheus (internal only, IP whitelist)
   - OpenSearch dashboards

### Phase 3: Security & Monitoring (Week 6)

8. **Implement Security Hardening** [4 hours]
   - Configure rate limiting
   - Add security headers
   - IP whitelisting for admin services
   - Test DDoS protection

9. **Configure Monitoring** [3 hours]
   - Prometheus ServiceMonitor for NGINX metrics
   - Grafana dashboard for ingress monitoring
   - Alerting rules for high error rates
   - Log aggregation for access logs

10. **Create Dojo Lab Automation** [4 hours]
    - Automated ingress provisioning for learner namespaces
    - Dynamic subdomain creation (learner-01.labs.fawkes.dev)
    - Wildcard certificate management
    - Cleanup automation

### Phase 4: Documentation & Training (Week 7)

11. **Write Comprehensive Documentation** [6 hours]
    - Architecture overview with diagrams
    - Configuration patterns and best practices
    - Troubleshooting guide (common issues)
    - Security hardening checklist

12. **Create Dojo Module Content** [4 hours]
    - Yellow Belt Module: "Exposing Services with Ingress"
    - Hands-on lab: Create custom ingress
    - Assessment questions on TLS, routing, security
    - Video walkthrough (15 minutes)

## Dojo Integration

### Yellow Belt - Module 4: "Exposing Services with Ingress"

**Learning Objectives**:
- Understand Kubernetes Ingress concepts
- Configure NGINX Ingress Controller
- Implement TLS/SSL with cert-manager
- Apply security best practices (rate limiting, headers)
- Troubleshoot common ingress issues

**Hands-On Lab**:
1. Deploy a sample application to learner namespace
2. Create Ingress resource with subdomain routing
3. Configure TLS certificate via cert-manager
4. Test HTTPS access and forced redirect
5. Add rate limiting and security headers
6. Monitor ingress metrics in Grafana

**Assessment**:
- Quiz on Ingress concepts (5 questions)
- Practical: Deploy and expose a new service
- Troubleshoot broken ingress configuration

**Time**: 90 minutes (30 min theory + 60 min hands-on)

## Monitoring & Observability

### Key Metrics

**NGINX Ingress Controller Metrics**:
- `nginx_ingress_controller_requests` - Total requests per service
- `nginx_ingress_controller_request_duration_seconds` - Request latency percentiles
- `nginx_ingress_controller_response_size` - Response sizes
- `nginx_ingress_controller_ssl_expire_time_seconds` - Certificate expiration
- `nginx_ingress_controller_nginx_process_connections` - Active connections

**Grafana Dashboard Panels**:
1. Request Rate (per service, per ingress)
2. Request Duration (P50, P95, P99)
3. HTTP Status Codes (2xx, 4xx, 5xx rates)
4. SSL Certificate Expiration Timeline
5. Ingress Controller Resource Usage (CPU, memory)
6. Error Rate by Service

**Alerting Rules**:
```yaml
groups:
- name: ingress_alerts
  rules:
  - alert: HighErrorRate
    expr: sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m])) / sum(rate(nginx_ingress_controller_requests[5m])) > 0.05
    for: 5m
    annotations:
      summary: "High 5xx error rate detected"

  - alert: CertificateExpiring
    expr: (nginx_ingress_controller_ssl_expire_time_seconds - time()) / 86400 < 7
    annotations:
      summary: "TLS certificate expiring in less than 7 days"

  - alert: HighLatency
    expr: histogram_quantile(0.95, nginx_ingress_controller_request_duration_seconds_bucket) > 5
    for: 10m
    annotations:
      summary: "P95 latency above 5 seconds"
```

## Security Considerations

### TLS/SSL Management

1. **Certificate Rotation**: cert-manager automatically renews certificates 30 days before expiration
2. **Protocol Enforcement**: Only TLSv1.2 and TLSv1.3 allowed
3. **Cipher Suites**: Strong ciphers only, no deprecated algorithms
4. **HSTS**: Strict-Transport-Security header enforced

### Rate Limiting

Per-Service Defaults:
- Public services (Backstage): 100 requests/second per IP
- Internal services (Jenkins, ArgoCD): 50 requests/second per IP
- Admin services (Prometheus): 10 requests/second per IP

### IP Whitelisting

Sensitive services restricted to:
- Corporate VPN CIDR blocks
- Platform team IP ranges
- CI/CD pipeline source IPs

### Web Application Firewall (WAF)

ModSecurity integration (post-MVP):
- OWASP Core Rule Set (CRS)
- SQL injection prevention
- XSS attack blocking
- Request validation

## Cost Analysis

### AWS Deployment (Production)

**Infrastructure**:
- Network Load Balancer: $16/month + $0.006/GB data transfer
- EBS volumes (NGINX controller state): $8/month for 80GB
- Data transfer (estimated 1TB/month): $90/month

**NGINX Controller Resources**:
- 3 replicas × 0.5 CPU × $0.04/hour = $43/month
- 3 replicas × 512MB RAM × $0.005/hour = $5/month

**Total Monthly Cost**: ~$162/month

**Cost Optimization**:
- Use AWS ALB for learner/dev environments (cheaper)
- Reduce replica count in non-production
- Implement caching to reduce data transfer

### Multi-Environment Cost Breakdown

| Environment | Load Balancer | Replicas | Monthly Cost |
|------------|---------------|----------|--------------|
| Production | NLB | 3 | $162 |
| Staging | ALB | 2 | $40 |
| Development | NodePort | 1 | $0 |
| Learner Labs | ALB (shared) | 2 | $40 |

## Documentation Structure

### For Platform Teams

1. **Architecture Overview**
   - Request flow diagrams
   - TLS termination architecture
   - Certificate management workflow
   - Multi-environment routing strategy

2. **Deployment Guide**
   - Helm chart installation
   - Configuration recommendations
   - Cloud-specific considerations
   - Troubleshooting common issues

3. **Operations Runbook**
   - Certificate renewal procedures
   - Ingress controller upgrades
   - Scaling guidelines
   - Incident response procedures

### For Dojo Learners

1. **Concepts Tutorial**
   - What is an Ingress Controller?
   - How TLS/SSL works
   - Routing strategies comparison
   - Security best practices

2. **Hands-On Lab Guide**
   - Step-by-step ingress creation
   - TLS configuration walkthrough
   - Troubleshooting exercises
   - Real-world scenarios

3. **Reference Materials**
   - Annotation cheat sheet
   - Common patterns library
   - Error message decoder
   - kubectl commands reference

## Migration Path

### From Default Cloud Ingress

If organizations start with cloud-native ingress:

1. **Week 1**: Deploy NGINX Ingress alongside existing ingress
2. **Week 2**: Migrate non-critical services to NGINX
3. **Week 3**: Validate routing, TLS, monitoring
4. **Week 4**: Migrate critical services with rollback plan
5. **Week 5**: Decommission cloud ingress controller

**Rollback Strategy**: Maintain both controllers for 2 weeks, allow instant DNS cutover

### From Path-Based to Subdomain Routing

1. Configure subdomain routing for new services
2. Maintain path-based routing for existing services
3. Gradually migrate services based on traffic patterns
4. Update documentation and bookmarks
5. Deprecate path-based routing after 6 months

## Related Decisions

- **ADR-001**: Kubernetes for Container Orchestration (ingress is Kubernetes-native)
- **ADR-002**: Backstage for Developer Portal (primary ingress endpoint)
- **ADR-009**: External Secrets Operator (integrates with ingress for secrets)
- **Future ADR**: OAuth2 Proxy for Unified Authentication (auth layer on ingress)
- **Future ADR**: Service Mesh (potential Istio migration path)

## References

- NGINX Ingress Controller Documentation: https://kubernetes.github.io/ingress-nginx/
- cert-manager Documentation: https://cert-manager.io/docs/
- CNCF Ingress Controller Comparison: https://docs.google.com/spreadsheets/d/191WWNpjJ2za6-nbG4ZoUMXMpUK8KlCIosvQB0f-oq3k
- OWASP TLS Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html
- Kubernetes Ingress Concepts: https://kubernetes.io/docs/concepts/services-networking/ingress/

## Notes

**Production Readiness Checklist**:
- [ ] 3+ replicas for high availability
- [ ] Cloud load balancer provisioned
- [ ] TLS certificates from trusted CA (Let's Encrypt or corporate)
- [ ] Rate limiting configured
- [ ] Security headers enabled
- [ ] Monitoring dashboards created
- [ ] Alerting rules configured
- [ ] Runbook documented
- [ ] Team trained on ingress operations

**Learner Environment Considerations**:
- Use path-based routing to minimize DNS complexity
- Provide pre-configured ingress templates
- Automate certificate provisioning
- Create self-service ingress creation workflow
- Include ingress troubleshooting in curriculum

## Last Updated

December 7, 2024 - Initial version documenting NGINX Ingress Controller selection
