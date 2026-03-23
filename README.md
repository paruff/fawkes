# Fawkes — Internal Product Delivery Platform

<p align="center">
  <a href="https://github.com/paruff/fawkes/actions/workflows/code-quality.yml">
    <img src="https://github.com/paruff/fawkes/actions/workflows/code-quality.yml/badge.svg" alt="CI"/>
  </a>
  <a href="https://github.com/paruff/fawkes/actions/workflows/pre-commit.yml">
    <img src="https://github.com/paruff/fawkes/actions/workflows/pre-commit.yml/badge.svg" alt="Pre-commit"/>
  </a>
  <a href="https://github.com/paruff/fawkes/actions/workflows/security-and-terraform.yml">
    <img src="https://github.com/paruff/fawkes/actions/workflows/security-and-terraform.yml/badge.svg" alt="Security"/>
  </a>
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"/>
</p>

Fawkes is an open-source **Internal Product Delivery Platform** that wires together
Backstage, ArgoCD, Jenkins, Prometheus, and a belt-level Dojo learning environment
into a single GitOps-managed stack. Deploy it locally in ~20 minutes with
`make dev-up`, or to AWS EKS in 2–4 hours. DORA metrics (deployment frequency,
lead time, change failure rate, mean time to restore) are collected automatically from day one.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Fawkes Product Delivery Platform                │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐    │
│  │       Backstage Developer Portal + Dojo Hub        │    │
│  └────────────────────────────────────────────────────┘    │
│           │                                                  │
│  ┌────────┴─────────┬──────────────┬─────────────┐        │
│  │  Collaboration   │   Project    │    Dojo     │        │
│  │  (Mattermost)    │ (Focalboard) │  Learning   │        │
│  └──────────────────┴──────────────┴─────────────┘        │
│           │                                                  │
│  ┌────────┴──────────────────────────────────────┐        │
│  │   CI/CD • GitOps • Observability • Security   │        │
│  └───────────────────────────────────────────────┘        │
│           │                                                  │
│  ┌────────┴──────────────────────────────────────┐        │
│  │  Kubernetes + Multi-Cloud Infrastructure      │        │
│  └───────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

→ [Full architecture overview](docs/architecture.md)

---

## Who Is Fawkes For?

- **Platform engineering teams** who want a production-ready IDP without starting from scratch.
- **DevOps teams** moving toward platform engineering and needing a concrete reference implementation.
- **Engineering leaders** who want automated DORA metrics and a paved path to elite delivery performance.
- **Platform engineering learners** who want hands-on labs on real infrastructure instead of sandbox toys.

---

## Prerequisites

| Tool    | Minimum version | Install |
|---------|-----------------|---------|
| Docker  | 24+             | <https://docs.docker.com/get-docker/> |
| k3d     | 5+              | `brew install k3d` or <https://k3d.io/#installation> |
| kubectl | 1.28+           | `brew install kubectl` |
| Helm    | 3.12+           | `brew install helm` |
| Make    | any             | Pre-installed on macOS/Linux |

**Resource requirements:** 4 CPU cores · 8 GB RAM · 20 GB free disk space

---

## Quick Start

```bash
git clone https://github.com/paruff/fawkes.git && cd fawkes
make check-deps          # verify prerequisites
make dev-up              # spin up local k3d cluster (~20 min)
make dev-status          # print service URLs and credentials
open http://localhost:8080
```

After `make dev-up` completes you will have:

```
  Service    URL                           Credentials
  ---------  ----------------------------  -------------------------
  Backstage  http://localhost:8080         (open access)
  ArgoCD     http://localhost:8080/argocd  admin / see dev-status
  Grafana    http://localhost:8080/grafana admin / fawkes-grafana
  Sample app http://localhost:8080/podinfo (open access)
```

Run `make dev-down` to tear down the cluster when you are done.

→ For a full AWS production deployment, see [docs/getting-started.md](docs/getting-started.md).

---

## Documentation

- [Getting Started](docs/getting-started.md)
- [Architecture Overview](docs/architecture.md)
- [Dojo Learning Environment](docs/dojo/DOJO_ARCHITECTURE.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Coding Standards](CODING_STANDARDS.md)
- [Troubleshooting](docs/troubleshooting.md)

---

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned features.

---

## Contributing

Contributions are welcome — code, docs, dojo content, and bug reports.

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
2. Browse [good first issues](https://github.com/paruff/fawkes/labels/good%20first%20issue).
3. Set up pre-commit hooks: `make pre-commit-setup`
4. Submit a pull request.

Questions? Start a [GitHub Discussion](https://github.com/paruff/fawkes/discussions).

---

## License

Fawkes is licensed under the [MIT License](LICENSE).
