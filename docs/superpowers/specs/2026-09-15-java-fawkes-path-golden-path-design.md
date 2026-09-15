# java-fawkes-path Golden Path — Design Spec

**Issue:** #2032
**Status:** Draft
**Date:** 2026-09-15

---

## 1. Goal

Create a Java golden path (`java-fawkes-path`) that mirrors `python-fawkes-path`'s end-to-end pipeline (Tekton CI → GitOps → ArgoCD → Argo Rollouts → observability), proving the golden path pattern works for JVM services.

## 2. Scope

### In Scope

- **Application**: Simple Spring Boot REST service (hello-world equivalent) with `/health`, `/metrics`, `/info` endpoints
- **CI Pipeline**: Tekton PipelineTask for Java (Maven build, JUnit tests, Trivy scan, container build, Cosign sign)
- **GitOps Repo**: `paruff/java-fawkes-path-gitops` with deployment, service, ServiceAccount, ServiceMonitor, ingress
- **ArgoCD Application**: ArgoCD Application + ApplicationSet (alpha/beta/prod)
- **Argo Rollouts**: Canary strategy with AnalysisTemplate (mirroring python-fawkes-path)
- **Observability**: OTEL traces, Prometheus metrics, ServiceMonitor
- **Golden Path Validation**: 8-plane validation scripts adapted for Java

### Out of Scope

- Database integration (PostgreSQL, etc.)
- Multi-module Maven projects
- GraalVM native image
- Quarkus (use Spring Boot for initial golden path)

## 3. Architecture

```
java-fawkes-path (repo)
  ├─ src/main/java/.../Application.java
  ├─ src/main/java/.../HealthController.java
  ├─ src/main/resources/application.yml
  ├─ pom.xml
  ├─ Dockerfile
  └─ catalog-info.yaml

java-fawkes-path-gitops (repo)
  ├─ deployment.yaml (Argo Rollouts)
  ├─ service.yaml
  ├─ serviceaccount.yaml (with IRSA annotation)
  ├─ servicemonitor.yaml
  ├─ ingress.yaml
  └─ kustomization.yaml

fawkes repo (platform/)
  ├─ platform/apps/java-fawkes-path/
  │   ├─ java-fawkes-path-application.yaml
  │   ├─ java-fawkes-path-alpha-applicationset.yaml
  │   ├─ java-fawkes-path-beta-applicationset.yaml
  │   ├─ java-fawkes-path-prod-applicationset.yaml
  │   ├─ java-fawkes-path-analysis-template.yaml
  │   └─ java-fawkes-path-analysis-template-application.yaml
  ├─ platform/apps/tekton/
  │   └─ java-golden-path-pipeline.yaml (new)
  └─ tests/integration/
      └─ test_java_fawkes_path_golden_path.py (new)
```

## 4. Tekton Pipeline (Java)

New `java-golden-path-pipeline.yaml` based on the Python golden path pattern:

| Step | Tool | Purpose |
|------|------|---------|
| git-clone | git | Clone source |
| mvn-build | Maven 3.9 + JDK 21 | Compile + package |
| mvn-test | Maven + JUnit 5 | Unit + integration tests |
| sonarqube-scan | SonarScanner | Code quality |
| trivy-scan | Trivy | CVE scan (binary + container) |
| build-container | Buildah/Kaniko | Build OCI image |
| cosign-sign | Cosign | Keyless signature |
| push-ghcr | Crane | Push to ghcr.io/paruff/java-fawkes-path |
| gitops-update | kustomize + git | Update GitOps repo image tag |
| dora-record | curl + Prometheus | Record deployment metadata |

## 5. Application Design

Minimal Spring Boot 3.3 app:

```java
@RestController
public class HealthController {
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }

    @GetMapping("/metrics")
    public String metrics() {
        // Expose Prometheus metrics via Micrometer
        return "# HELP java_fawkes_path_requests_total\n...";
    }
}
```

- **Port**: 8080
- **Image**: `ghcr.io/paruff/java-fawkes-path:latest`
- **Resources**: requests 128Mi/250m, limits 256Mi/500m

## 6. IRSA Wiring

After `terraform apply` in `infra/aws/`:

```bash
export JAVA_FAWKES_PATH_IRSA_ROLE_ARN=$(cd infra/aws && terraform output -raw java_fawkes_path_irsa_role_arn)
```

Hardcode in `java-fawkes-path-gitops/serviceaccount.yaml`:

```yaml
annotations:
  eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT:role/fawkes-java-fawkes-path-irsa"
```

Terraform module: add `java_fawkes_path_irsa` alongside `python_fawkes_path_irsa` in `infra/aws/main.tf`.

## 7. Golden Path Validation Scripts

Adapt 8 existing scripts for Java:

| Script | Java-specific changes |
|--------|----------------------|
| `validate-golden-path-pipeline.sh` | Check Maven build logs, JUnit reports |
| `validate-golden-path-resources.sh` | Same (generic K8s checks) |
| `validate-golden-path-security.sh` | Same (Cosign, Trivy, securityContext) |
| `validate-golden-path-observability.sh` | Same (OTEL traces, Prometheus metrics) |
| `validate-golden-path-gitops.sh` | Same (ArgoCD sync status) |
| `validate-golden-path-devex.sh` | Same (Backstage catalog) |
| `validate-golden-path-dora.sh` | Same (DORA metrics) |
| `validate-golden-path-progressive-delivery.sh` | Same (Argo Rollouts) |

## 8. Acceptance Criteria

- [ ] `java-fawkes-path` app builds and runs locally (`mvn spring-boot:run`)
- [ ] Tekton pipeline passes: build → test → scan → sign → push → gitops-update
- [ ] ArgoCD Application syncs and shows Synced/Healthy
- [ ] Argo Rollouts canary strategy works with AnalysisTemplate
- [ ] OTEL traces reach Tempo
- [ ] Prometheus scrapes `/metrics` endpoint
- [ ] All 8 golden path validation scripts pass
- [ ] IRSA role ARN wired (after terraform apply)
- [ ] Backstage catalog entry exists

## 9. Effort Estimate

| Task | Hours |
|------|-------|
| Spring Boot app + Dockerfile | 2h |
| Tekton pipeline (Java) | 3h |
| GitOps repo setup | 2h |
| ArgoCD Application + ApplicationSet | 1h |
| Argo Rollouts + AnalysisTemplate | 2h |
| IRSA wiring (Terraform + gitops) | 1h |
| Golden path validation scripts | 3h |
| Integration test suite | 2h |
| **Total** | **16h** |

## 10. Dependencies

- #1578 pattern (IRSA wiring) — already done for Python, replicate for Java
- Tekton pipeline infrastructure (already running)
- Argo Rollouts controller (already installed)
- Chaos Mesh (#1939) — optional, for chaos experiments
