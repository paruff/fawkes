---
name: artifact-contract-validation
description: "Ensure all required artifacts are produced and consumed correctly. Use when validating version.json, SBOM, signatures, or manifest outputs."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Artifact Contract Validation

> **Load trigger:** `"load artifact-contract-validation skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure all required artifacts are produced and consumed correctly.

## Responsibilities

- Validate version.json
- Validate SBOM
- Validate signatures
- Validate manifest outputs

## Inputs

- Build artifacts

## Outputs

- `artifact-contracts.json`

## Required Artifacts

| Artifact       | Produced By   | Consumed By     | Format         |
| -------------- | ------------- | --------------- | -------------- |
| `version.json` | build         | publish, deploy | JSON           |
| `sbom.json`    | security-scan | release         | SPDX/CycloneDX |
| `image_digest` | build         | deploy          | sha256         |
| `signature`    | publish       | deploy          | Cosign         |
| `manifests`    | build         | deploy          | YAML           |
| `CHANGELOG.md` | changelog     | release         | Markdown       |

## Validation Rules

- [ ] All required artifacts exist
- [ ] Artifact formats valid
- [ ] Artifacts passed correctly between stages
- [ ] No missing artifacts at publish/deploy

## Output Format

```json
{
  "skill": "artifact-contract-validation",
  "status": "pass | fail",
  "artifacts": {
    "version.json": "present",
    "sbom.json": "present",
    "image_digest": "present",
    "signature": "present",
    "manifests": "present"
  },
  "missing": []
}
```

## Success Criteria

- All required artifacts present and valid
- Correct artifact flow between stages
