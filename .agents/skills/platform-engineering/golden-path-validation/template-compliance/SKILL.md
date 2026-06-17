---
name: template-compliance
description: "Ensure project structure matches uFawkesAI template. Use when validating directory structure, required files, or required workflows."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Template Compliance

> **Load trigger:** `"load template-compliance skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Ensure project structure matches uFawkesAI template.

## Responsibilities

- Validate directory structure
- Validate required files
- Validate required workflows

## Inputs

- Project repo
- Template manifest

## Outputs

- `template-compliance.json`

## Required Structure

```
project/
├── src/                    # Source code
├── tests/                  # Test files
├── manifests/              # K8s manifests
├── overlays/               # Kustomize overlays
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .github/workflows/      # CI/CD workflows
├── .devcontainer/          # Dev environment
├── pipeline-spec.yaml      # Pipeline definition
├── version.json            # Version tracking
├── Dockerfile              # Container build
└── README.md               # Documentation
```

## Validation Rules

- [ ] All required directories exist
- [ ] All required files exist
- [ ] Directory structure matches template
- [ ] No extra top-level directories

## Output Format

```json
{
  "skill": "template-compliance",
  "status": "pass | fail",
  "structure": {
    "valid_dirs": ["src/", "tests/", "manifests/", "overlays/", ".github/workflows/"],
    "missing_dirs": [],
    "valid_files": ["pipeline-spec.yaml", "version.json", "Dockerfile", "README.md"],
    "missing_files": []
  }
}
```

## Success Criteria

- No missing template components
- Structure matches template exactly
