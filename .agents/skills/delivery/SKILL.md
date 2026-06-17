---
name: delivery
description: "Validate and deliver manifests for deployment. Use when validating manifests, creating PRs, and ensuring deployment readiness."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Delivery

> **Load trigger:** `"load delivery skill"` > **DORA:** Cap 4 (Continuous Delivery)
> **Token cost:** Low

## Purpose

Validate and deliver manifests for deployment.

## Responsibilities

- Validate Kubernetes manifests
- Detect configuration drift
- Test environment promotion
- Validate reconciliation
- Create deployment PRs
- Ensure deployment readiness

## Dependencies

| Skill    | Relationship                    |
| -------- | ------------------------------- |
| `build`  | Consumes manifests and overlays |
| `review` | Validates review findings       |

## Inputs

- Kubernetes manifests (from build)
- GitOps overlays (from build)
- Review findings (from review)

## Outputs

- `delivery-report.json`
- PR (created and ready for merge)

## Delivery Rules

### Manifest Validation

- [ ] Manifests are valid YAML
- [ ] Required fields present
- [ ] Resource limits defined
- [ ] Security contexts set

### Drift Detection

- [ ] No unauthorized changes
- [ ] GitOps state is authoritative
- [ ] Cluster state matches desired state

### Environment Promotion

- [ ] Dev → Staging → Prod order
- [ ] Configuration differences documented
- [ ] Rollback plan defined

### Deployment Readiness

- [ ] All tests passing
- [ ] Security scan clean
- [ ] Review approved
- [ ] Documentation updated

## Output Format

```json
{
  "skill": "delivery",
  "status": "pass | fail",
  "validation": {
    "manifests_valid": true,
    "drift_detected": false,
    "promotion_ready": true
  },
  "pr": {
    "number": 123,
    "url": "https://github.com/org/repo/pull/123",
    "status": "ready-for-merge"
  },
  "readiness": {
    "tests_passing": true,
    "security_clean": true,
    "review_approved": true
  }
}
```

## Success Criteria

- All manifests valid
- No drift detected
- PR created and ready
- Deployment readiness confirmed
