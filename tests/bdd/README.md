# BDD tests (behave) — Backstage steps

This folder contains Behave (BDD) step definitions and feature files for Backstage deployment tests.

Prerequisites
- Python 3.8+ and a virtual environment
- `helm` and `kubectl` available in PATH on the machine running the tests
- kubeconfig configured locally or tests run inside a Kubernetes cluster (in-cluster config)
- The target container image used by the Backstage pod must include `curl` (or adjust health-check step)

Recommended quick setup (macOS / zsh)

```bash
# create and activate venv
python3 -m venv .venv
source .venv/bin/activate

# install requirements (the repo's requirements.txt should include behave and kubernetes)
pip install -r requirements.txt

# If the kubernetes or behave packages are missing, install explicitly
pip install behave kubernetes
```

Environment variables and inputs used by the steps
- KUBECONFIG (optional): path to kubeconfig. If unset the client will use the default (~/.kube/config) or in-cluster config.
- HELM binary: `helm` is invoked via PATH. If you need a different binary path, run tests in an environment where that binary is named `helm` or adjust the step definitions.
- The Behave steps expect feature scenarios to provide chart path, release name, namespace and values file arguments. Example feature uses placeholders like:
  - chart path (e.g. `infra/kubernetes/backstage`) 
  - release name (e.g. `backstage`) 
  - namespace (e.g. `fawkes-platform`) 

How the tests run (examples)

Run the whole Backstage feature:

```bash
behave tests/bdd/features/backstage-deployment.feature
```

Run a single scenario by name:

```bash
behave tests/bdd/features/backstage-deployment.feature --name "Scenario name"
```

Notes & troubleshooting
- If the health-check step fails because `curl` is not available inside the pod, you can either:
  - Add `curl` to the container image used by the chart, or
  - Modify the step `tests/bdd/step_definitions/backstage_steps.py` to use an alternate check (e.g., `wget`, `nc`, or port-forward + local HTTP request).
- Ensure `helm` can access any private registries (credentials) used by the chart (e.g., via `helm repo add` and authentication) before running the tests.
- The Kubernetes client used by the steps loads kubeconfig with `kubernetes.config.load_kube_config()` then falls back to `load_incluster_config()`. If you want to force a particular kubeconfig, set `KUBECONFIG` before running the tests.

Example local run with explicit kubeconfig and values file (zsh):

```bash
export KUBECONFIG=~/.kube/config
behave tests/bdd/features/backstage-deployment.feature --name "Deploy Backstage from chart"
```

If you'd like, I can also:
- Add a small wrapper script (bash) to set up the virtualenv and run behave with common variables, or
- Add an alternative health-check implementation that uses `kubectl port-forward` and a local `requests` call instead of `curl` in the pod.
