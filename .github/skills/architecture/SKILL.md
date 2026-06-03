> Load with: "architecture skill" in your prompt
> Example: "Use the architecture skill to implement this feature."

# Fawkes Architecture Skill

## Layer structure diagram
```text
services/  -> Python FastAPI business logic and APIs
     |     no direct cloud provisioning
     v
platform/ + charts/ -> Helm, Kubernetes, ArgoCD desired state
     |               no imperative scripts or business logic
     v
infra/ -> Terraform modules and cloud resources

scripts/ -> automation that calls services and CLIs; never business logic
tests/   -> unit, integration, BDD, and Terratest coverage for the layers above
docs/    -> architecture, API, runbooks, metrics, and golden-path guidance
```

## Dependency direction rules
- Dependencies flow downward: services -> platform -> infra.
- `services/` stays stateless and does not provision cloud resources.
- `platform/` declares desired state and does not contain imperative deploy logic.
- `infra/` provisions resources only and never imports application logic.
- `scripts/` orchestrates CLIs and services, but business rules belong in services.
- Terratest Go code belongs in `tests/terratest/`, not in `services/`.

## Hard architectural rules
- No hardcoded credentials, regions, account IDs, or mutable image tags.
- Environment-specific Kubernetes values belong in overrides, not base `values.yaml`.
- Every container spec needs resource limits and standard labels.
- Terraform variables and outputs need `description` fields.
- Cross-layer changes must update docs and impact maps in the same PR.

## What to read before writing code
1. `docs/ARCHITECTURE.md` for component relationships and allowed dependencies.
2. `docs/CHANGE_IMPACT_MAP.md` for cross-component blast radius.
3. `docs/API_SURFACE.md` before changing service contracts.
4. `docs/KNOWN_LIMITATIONS.md` before changing behavior around known gaps.
5. Representative files in the target directory before adding new patterns.

## PR architecture checklist
- [ ] The change stays within a valid layer boundary.
- [ ] Any API, env var, or values key rename is reflected in dependent files and docs.
- [ ] Infra/platform changes document rollout or validation impact.
- [ ] New architecture assumptions are captured in docs if they outlive the PR.
- [ ] No imperative shortcut was introduced to bypass GitOps or Terraform flows.
