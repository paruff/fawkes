# Update automation: what is covered (#2366 step 4)

Read from `.github/dependabot.yml` on 2026-11-27. The Renovate column is from its
documentation and has **not** been trialled on this repository.

| Where versions live | Dependabot today | Renovate could |
|---|---|---|
| GitHub Actions | yes | yes |
| pre-commit hooks | yes | yes (opt-in) |
| Python `requirements*.txt` | only the repository root (`/`) | yes, all files |
| Dockerfiles | only `services/mcp-k8s-server` | yes, all files |
| Terraform | `infra/terraform`, `infra/aws`, `infra/azure` only; not module subdirectories | yes |
| npm, Go modules | no version updates configured | yes |
| Argo CD `targetRevision` | no, unsupported | yes, `argocd` manager with file patterns set |
| `image:` in manifests and Tekton tasks | no | yes, `kubernetes`/`tekton` managers with file patterns set |
| Shell `*_CHART_VERSION`, download URLs, workflow tool versions | no | partly, with custom regex managers |
| Kubernetes / AKS versions, vendored Tekton YAML | no | no practical coverage |

## Recommendation

Adopt Renovate for what Dependabot cannot read, with `minimumReleaseAge: 7 days`
to match ADR-040, and turn off the overlapping Dependabot entries so there is one
update PR per change. This needs a maintainer to install the Renovate app, so it
is a decision, tracked in #2386.

Until then, nothing reports a new Argo CD-installed chart. The guard test only
catches disagreement and floating versions, not age.
