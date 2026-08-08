# Build Report — security: fix insecure security-group/endpoint defaults in unused AWS library modules (#1534)

**Status:** COMPLETE

---

## Context

GitHub issue #1534 (P1, `type-security`, `terraform`): the unused AWS library modules
`infra/terraform/modules/aws/{rds,eks}` hardcode `0.0.0.0/0` on security-group egress
and on the EKS API-server authorized IP ranges default, which Trivy flagged as
unrestricted egress / open CIDR public access (#459, #458, #457). Zero live callers
confirmed — only README usage examples reference the modules, and `examples/` contains
only the `vpc` example (unaffected).

## Design decision (judgment call flagged for human review)

To scope egress to the VPC CIDR **without** adding a new required input, I used a
`data "aws_vpc"` lookup on the existing `vpc_id` (the same pattern the upstream
`terraform-aws-modules/rds` uses) plus an `egress_cidr_blocks` override variable
(default `[]` → falls back to the looked-up VPC CIDR). This satisfies the issue's
"real default + override var" without forcing future callers to pass a new `vpc_cidr`
variable. The EKS public-endpoint model (`endpoint_public_access` /
`public_access_cidrs`) was **not** touched — the issue explicitly scopes that out as a
separate issue.

## Tasks Completed

| Task                       | Title                                                                  | Files | Status |
| -------------------------- | ---------------------------------------------------------------------- | ----- | ------ |
| RDS egress default         | Replace `0.0.0.0/0` egress with VPC-CIDR-scoped default + override var | 2     | DONE   |
| EKS egress default         | Replace `0.0.0.0/0` egress with VPC-CIDR-scoped default + override var | 2     | DONE   |
| EKS API ranges default     | `api_server_authorized_ip_ranges` default `[]` + wildcard validation   | 1     | DONE   |
| README examples            | Update usage examples + terraform-docs tables                          | 2     | DONE   |

## Changes

### `infra/terraform/modules/aws/rds/main.tf`

- Added `data "aws_vpc" "this" { id = var.vpc_id }`
- Egress: `cidr_blocks = length(var.egress_cidr_blocks) > 0 ? var.egress_cidr_blocks : [data.aws_vpc.this.cidr_block]`

### `infra/terraform/modules/aws/rds/variables.tf`

- Added `egress_cidr_blocks` (list(string), default `[]`, CIDR-validated)

### `infra/terraform/modules/aws/eks/main.tf`

- Added `data "aws_vpc" "this" { id = var.vpc_id }`
- Egress: same VPC-CIDR-scoped default pattern

### `infra/terraform/modules/aws/eks/variables.tf`

- `api_server_authorized_ip_ranges`: default `["0.0.0.0/0"]` → `[]`; description updated;
  added validation block rejecting `0.0.0.0/0`
- Added `egress_cidr_blocks` (same as RDS)

### READMEs (`rds`, `eks`)

- Usage example: `api_server_authorized_ip_ranges = ["203.0.113.10/32"]` (documentation
  IP, no longer the wildcard)
- Handwritten Inputs tables + terraform-docs-generated tables updated

## Validation Results

| Check                       | Status | Notes                                                                  |
| --------------------------- | ------ | ---------------------------------------------------------------------- |
| `terraform fmt -check`      | PASS   | Recursive on both module dirs                                          |
| `terraform validate`        | PASS   | Both modules (validated in scratch copies; local `.terraform` cache had a stale symlink, unrelated to config) |
| `tflint`                    | PASS   | 0 issues, both modules                                                 |
| `tfsec`                     | PASS   | SG ingress/egress wildcard CRITICALs eliminated; remaining findings pre-existing and out of scope (endpoint model, secret encryption, cluster-autoscaler IAM wildcard, log-group CMK — issue explicitly excludes them) |
| `terraform-docs`            | PASS   | Both READMEs regenerated                                              |
| Examples unaffected         | PASS   | `examples/` contains only `vpc`; no RDS/EKS snapshots to break         |
| No live callers             | PASS   | Grep confirms only README references; zero TF callers                 |

## Artifacts Produced

- [x] Source changes in `infra/terraform/modules/aws/rds/{main,variables}.tf`
- [x] Source changes in `infra/terraform/modules/aws/eks/{main,variables}.tf`
- [x] README updates (usage + docs tables) for both modules

## Blockers

None.

## Notes / Pre-existing issues (not fixed, out of scope)

- EKS README has **two** `BEGIN_TF_DOCS` blocks (duplicate; the first was already
  stale before this change — provider versions `6.27.0` vs `6.57.1`). terraform-docs
  only refreshes the last block; I manually corrected the stale `0.0.0.0/0` value in
  the first block but did not remove the duplication.
- `data "aws_vpc"` requires `ec2:DescribeVpcs` on the caller's IAM role; already
  required to resolve `vpc_id`, so no new permission burden.
- 6 files touched (just over the 5-file ask-before threshold) — all within the
  explicit file list in the issue body, flagged here for the record.
