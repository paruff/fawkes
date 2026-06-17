---
name: golden-paths
description: "Validate projects follow Fawkes conventions. Use when checking testing, security, observability, and release patterns."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Golden Paths

> **Load trigger:** `"load golden-paths skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure projects follow Fawkes conventions for testing, security, observability, and release.

## Responsibilities

- Validate testing patterns
- Check security compliance
- Verify observability setup
- Ensure release conventions
- Detect deviations from golden paths

## Dependencies

| Skill    | Relationship              |
| -------- | ------------------------- |
| `build`  | Validates build output    |
| `review` | Validates review findings |

## Inputs

- Project structure
- Configuration files
- Test files
- Security configurations
- Observability configurations

## Outputs

- `golden-paths-report.json`

## Validation Rules

### Testing

- [ ] Test framework configured
- [ ] Test files exist
- [ ] Coverage thresholds defined
- [ ] CI test stage present

### Security

- [ ] No hardcoded secrets
- [ ] Dependency scanning configured
- [ ] Container scanning configured
- [ ] SAST configured

### Observability

- [ ] Metrics endpoint defined
- [ ] Health check endpoint defined
- [ ] Structured logging configured
- [ ] Tracing configured

### Release

- [ ] Semantic versioning used
- [ ] Changelog maintained
- [ ] Release notes generated
- [ ] Artifacts signed

## Output Format

```json
{
  "skill": "golden-paths",
  "status": "pass | fail",
  "validation": {
    "testing": {
      "status": "pass | fail",
      "issues": []
    },
    "security": {
      "status": "pass | fail",
      "issues": []
    },
    "observability": {
      "status": "pass | fail",
      "issues": []
    },
    "release": {
      "status": "pass | fail",
      "issues": []
    }
  },
  "score": 85
}
```

## Success Criteria

- All golden path checks pass
- No critical deviations
- Score above threshold (80%)
