# Changelog

All notable changes to the Fawkes platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Focalboard project management integration
- Mattermost collaboration platform integration
- White Belt dojo curriculum (initial modules)
- Chaos engineering integration (planned)

### Changed

- Ongoing documentation improvements and reorganization

## [0.3.0] - 2025-12-25

**Product discovery, design and adoption support**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/v0.3.0)

### Added

- User research repository structure with Git LFS and file validation
- Research-validated user personas with Backstage catalog integration
- Structured interview guides for platform user research
- Insights Database and Tracking System — REST API with tagging and full-text search
- Research Insights Dashboard with Prometheus metrics exporter
- AT-E3-001 acceptance test validation script for research infrastructure
- Anomaly detection service for platform observability
- AI code review service with multi-provider LLM support
- MCP Kubernetes server for AI-assisted cluster management
- Ansible-based VM provisioning and bootstrapping
- Design system foundations (CSS/JS component library)
- Sample applications and golden-path templates

### Changed

- Documentation restructured into Diataxis-aligned knowledge base
- README navigation and getting-started flow improved
- Root-level markdown files reorganized

## [0.2.0] - 2025-12-23

**AI features and data platform**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/v0.2.0)

### Added

- Weaviate vector database deployment for RAG (Retrieval-Augmented Generation)
- RAG service for AI context retrieval with Weaviate integration
- RAG indexers for GitHub repositories and Backstage TechDocs
- AI coding assistant configured with telemetry and RAG integration
- AI usage policy documentation and governance framework
- DataHub data catalog with PostgreSQL and OpenSearch backends
- DataHub metadata ingestion for PostgreSQL, Kubernetes, Git, and CI/CD sources
- AT-E2-001 and AT-E2-002 acceptance test runners with report generation
- Security plane — SBOM generation, image signing, and OPA policy enforcement
- DORA metrics automation with Prometheus dashboards

### Changed

- CI/CD pipelines updated to enforce code quality gates (ruff, mypy, shellcheck)
- Observability stack extended with OpenTelemetry tracing

## [0.1.0] - 2025-12-21

**Initial platform foundation**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/v0.1.0)

### Added

- Core platform architecture and governance documentation
- Jenkins CI/CD with Kubernetes pod/agent support (Configuration as Code)
- Pre-commit hooks for GitOps, Terraform, Kubernetes, and IDP validation
- Infrastructure as Code with Terraform (AWS, Azure modules)
- Kubernetes orchestration manifests and Helm chart foundations
- ArgoCD GitOps application definitions
- Backstage developer portal initial deployment
- Dojo learning system design and belt-progression framework
- Multi-cloud support groundwork (AWS, Azure, GCP)
- Observability stack (Prometheus, Grafana, OpenTelemetry) — initial setup
- CHANGELOG, CONTRIBUTING, and CODE_OF_CONDUCT documentation

[Unreleased]: https://github.com/paruff/fawkes/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/paruff/fawkes/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/paruff/fawkes/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/paruff/fawkes/releases/tag/v0.1.0
