"""Guard: every component version is pinned, and files that set it agree (#2366).

Rule: docs/adr/ADR-040-version-currency.md. Known violations live in
version_pin_exceptions.yaml, each with the issue that will remove it.
"""

import re
import subprocess
from pathlib import Path

import pytest
import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
EXCEPTIONS = Path(__file__).with_name("version_pin_exceptions.yaml")

FLOATING = {"", "latest", "head", "main", "master", "stable"}
# `*`, `1.x`, `>=1`, `~1`, `^1` all mean "whatever is newest".
RANGE = re.compile(r"[*<>~^]|(^|\.)x(\.|$)")
# apps-deferred is not installed by any bootstrap, so it is not part of the stack.
SKIPPED_DIRS = ("platform/apps-deferred/", "platform/apps/tekton/upstream/", "docs/", "tests/")

# `<PREFIX>_CHART_VERSION` in a shell script -> chart name.
SHELL_CHARTS = {
    "ARGOCD": "argo-cd",
    "INGRESS_NGINX": "ingress-nginx",
    "BACKSTAGE": "backstage",
    "PROMETHEUS": "kube-prometheus-stack",
    "VAULT": "vault",
}
# Files that set the Argo CD chart through a Terraform `chart_version`.
ARGOCD_TF_DEFAULTS = (
    "infra/terraform/argocd/variables.tf",
    "infra/terraform/modules/argocd-helm/variables.tf",
)
ARGOCD_TF_EXAMPLES = ("infra/terraform/argocd/README.md",)
WORKFLOW_TOOLS = ("go-version", "node-version", "python-version", "terraform_version", "tflint_version")

# Tools set in more than one kind of file.
TOOL_PATTERNS = {
    "golangci-lint": (
        r"golangci/golangci-lint\s+rev:\s*(v[\d.]+)",
        r"golangci-lint-action@.*\n\s*with:\s*\n\s*version:\s*(v[\d.]+)",
    ),
    "gitleaks": (r"gitleaks/gitleaks\s+rev:\s*(v[\d.]+)", r"GITLEAKS_VERSION=([\d.]+)"),
    "trivy": (r"aquasec/trivy:([\d.]+)", r"setup-trivy@.*\n\s*with:\s*\n(?:\s*#.*\n)*\s*version:\s*(v[\d.]+)"),
}
Pin = tuple[str, str, str]  # (component, version, file)


def application_pins(path: str, text: str) -> list[Pin]:
    """Chart versions from Argo CD Applications."""
    pins: list[Pin] = []
    for doc in yaml.safe_load_all(text):
        if not isinstance(doc, dict) or doc.get("kind") != "Application":
            continue
        spec = doc.get("spec") or {}
        for source in [spec.get("source"), *(spec.get("sources") or [])]:
            if source and source.get("chart"):
                pins.append((f"chart:{source['chart']}", str(source.get("targetRevision") or ""), path))
    return pins


def text_pins(path: str, text: str) -> list[Pin]:
    """Versions set outside Argo CD Applications."""
    pins: list[Pin] = []
    if path.endswith(".sh"):
        for prefix, version in re.findall(
            r'^[ \t]*(?:export[ \t]+)?([A-Z_]+)_CHART_VERSION="?([^"\s]*)"?', text, re.MULTILINE
        ):
            pins.append((f"chart:{SHELL_CHARTS.get(prefix, prefix)}", version, path))
    if path in ARGOCD_TF_DEFAULTS:
        block = re.search(r'variable "chart_version" \{.*?^\}', text, re.MULTILINE | re.DOTALL)
        default = re.search(r'default\s*=\s*"([^"]*)"', block.group(0)) if block else None
        pins.append(("chart:argo-cd", default.group(1) if default else "", path))
    if path in ARGOCD_TF_EXAMPLES:
        pins += [("chart:argo-cd", v, path) for v in re.findall(r'^chart_version\s*=\s*"([^"]*)"', text, re.MULTILINE)]
    if path.startswith(".github/"):
        for tool in WORKFLOW_TOOLS:
            pins += [
                (f"ci:{tool}", v, path)
                for v in re.findall(rf"^\s*{tool}:\s*[\"']?(v?\d[\w.]*|latest)[\"']?\s*(?:#.*)?$", text, re.MULTILINE)
            ]
    if path.endswith(".sh"):
        commands = re.sub(r"\\\n\s*", " ", text)
        # `repo/chart` installs only; local chart paths start with `$`, `.` or `/`.
        installs = re.findall(
            r"^[ \t]*helm (?:upgrade --install|install) \S+ ([a-z][\w-]*/[\w-]+)(.*)$", commands, re.MULTILINE
        )
        pins += [(f"chart:{chart.split('/')[1]}", "", path) for chart, rest in installs if "--version" not in rest]
        moving = re.findall(r"raw\.githubusercontent\.com/([\w.-]+/[\w.-]+)/(stable|main|master|HEAD)/", text)
        pins += [(f"url:{repo}", ref, path) for repo, ref in moving]
    for tool, patterns in TOOL_PATTERNS.items():
        for pattern in patterns:
            # Tools are written with and without the leading v.
            pins += [(f"tool:{tool}", "v" + v.removeprefix("v"), path) for v in re.findall(pattern, text)]
    images: list[str] = []
    if Path(path).name.startswith("Dockerfile"):
        froms = re.findall(r"^FROM\s+(?:--platform=\S+\s+)?([^\s@]+)(?:@\S+)?(?:\s+AS\s+(\S+))?", text, re.MULTILINE)
        stages = {"scratch", *(stage for _, stage in froms)}
        images = [ref for ref, _ in froms if ref not in stages and not ref.startswith("$")]
    elif path.endswith((".yaml", ".yml")):
        images = re.findall(
            r"^\s*(?:- )?image:\s*[\"']?([\w./:-]+:[\w.-]+|[\w.-]+(?:/[\w.-]+)+)[\"']?\s*(?:#.*)?$", text, re.MULTILINE
        )
        # Helm values name the tag on its own line, so name a floating one by file.
        tags = re.findall(r"^\s*tag:\s*[\"']?([\w.-]+)[\"']?\s*(?:#.*)?$", text, re.MULTILINE)
        pins += [(f"image-tag:{path}", t, path) for t in tags if t.lower() in FLOATING]
    for ref in images:
        # A colon before the last slash is a registry port, not a tag.
        colon = ref.rfind(":")
        image, tag = (ref[:colon], ref[colon + 1 :]) if colon > ref.rfind("/") else (ref, "")
        image = image.removeprefix("docker.io/").removeprefix("library/")
        # python:3.13.14-slim -> component image:python-slim, version 3.13.14
        version, _, variant = tag.partition("-")
        pins.append((f"image:{image}{'-' + variant if variant else ''}", version, path))
    return pins


def collect_pins(files: dict[str, str]) -> list[Pin]:
    pins: list[Pin] = []
    for path, text in files.items():
        if path.startswith(SKIPPED_DIRS):
            continue
        # Skip Helm templates: `{{ }}` at the start of a line is not valid YAML.
        if path.endswith((".yaml", ".yml")) and not re.search(r"^\s*\{\{", text, re.MULTILINE):
            if re.search(r"^kind:\s*Application\s*$", text, re.MULTILINE):
                pins += application_pins(path, text)
        pins += text_pins(path, text)
    return pins


def violations(pins: list[Pin]) -> dict[str, list[str]]:
    """component -> versions, for components that float or disagree."""
    versions: dict[str, set[str]] = {}
    for component, version, _ in pins:
        versions.setdefault(component, set()).add(version)
    return {
        component: sorted(found)
        for component, found in versions.items()
        if len(found) > 1 or any(v.lower() in FLOATING or RANGE.search(v) for v in found)
    }


def repo_files() -> dict[str, str]:
    names = subprocess.run(["git", "ls-files"], cwd=REPO_ROOT, capture_output=True, text=True, check=True).stdout
    wanted = (".yaml", ".yml", ".sh", ".tf", ".md")
    return {
        name: (REPO_ROOT / name).read_text()
        for name in names.splitlines()
        if (name.endswith(wanted) or Path(name).name.startswith("Dockerfile")) and (REPO_ROOT / name).is_file()
    }


def load_exceptions() -> dict[str, list[str]]:
    # shortcut: matches the set of versions, not which file holds each; record files if that hides drift.
    entries = yaml.safe_load(EXCEPTIONS.read_text()) if EXCEPTIONS.exists() else []
    for entry in entries:
        assert entry.get("issue") or entry.get("reason"), f"{entry['component']}: needs an issue or a reason"
    return {entry["component"]: sorted(entry["versions"]) for entry in entries}


def test_versions_are_pinned_and_agree() -> None:
    pins = collect_pins(repo_files())
    assert pins, "the guard found no versions at all"
    found, excepted = violations(pins), load_exceptions()
    problems = [
        f"{component}: {versions} in " + ", ".join(sorted({f"{f} ({v})" for c, v, f in pins if c == component}))
        for component, versions in sorted(found.items())
        if excepted.get(component) != versions
    ]
    problems += [
        f"{component}: exception is stale, update or remove it"
        for component, versions in sorted(excepted.items())
        if found.get(component) != versions
    ]
    assert not problems, "version pins (ADR-040):\n" + "\n".join(problems)


APPLICATION = """kind: Application
spec:
  source:
    chart: argo-cd
    targetRevision: {version}
"""


def test_guard_reports_two_files_that_disagree() -> None:
    files = {
        "platform/apps/a/a-application.yaml": APPLICATION.format(version="10.20.0"),
        "scripts/dev-up.sh": 'ARGOCD_CHART_VERSION="7.7.14"\n',
    }
    assert violations(collect_pins(files)) == {"chart:argo-cd": ["10.20.0", "7.7.14"]}


def test_guard_reports_unpinned_and_floating_versions() -> None:
    files = {
        "infra/terraform/argocd/variables.tf": 'variable "chart_version" {\n  default = ""\n}\n',
        "platform/apps/b/values.yaml": 'image:\n  tag: "latest"\n',
    }
    assert violations(collect_pins(files)) == {
        "chart:argo-cd": [""],
        "image-tag:platform/apps/b/values.yaml": ["latest"],
    }


def test_guard_accepts_agreeing_pins() -> None:
    files = {
        "platform/apps/a/a-application.yaml": APPLICATION.format(version="10.20.0"),
        "scripts/dev-up.sh": 'ARGOCD_CHART_VERSION="10.20.0"\n',
        "services/x/Dockerfile": "FROM python:3.13.18-slim AS build\nFROM python:3.13.18-slim\n",
    }
    assert violations(collect_pins(files)) == {}


def test_guard_compares_dockerfiles_with_manifest_images() -> None:
    files = {
        "services/x/Dockerfile": "FROM maven:3.9.16-eclipse-temurin-21\n",
        "templates/j/tekton-pipeline.yaml": "      image: docker.io/library/maven:3.9.9-eclipse-temurin-21\n",
        "platform/apps/c/deployment.yaml": "        - image: ghcr.io/paruff/nps:latest\n",
    }
    assert violations(collect_pins(files)) == {
        "image:maven-eclipse-temurin-21": ["3.9.16", "3.9.9"],
        "image:ghcr.io/paruff/nps": ["latest"],
    }


def test_guard_compares_pre_commit_hooks_with_ci_tools() -> None:
    files = {
        ".pre-commit-config.yaml": "  - repo: https://github.com/golangci/golangci-lint\n    rev: v2.15.0\n",
        ".github/workflows/q.yml": "      - uses: golangci/golangci-lint-action@abc  # v9\n"
        "        with:\n          version: v2.12.2\n",
    }
    assert violations(collect_pins(files)) == {"tool:golangci-lint": ["v2.12.2", "v2.15.0"]}


@pytest.mark.parametrize(
    ("path", "text", "component", "version"),
    [
        ("platform/a.yaml", APPLICATION.format(version="'*'"), "chart:argo-cd", "*"),
        ("platform/a.yaml", APPLICATION.format(version="10.x"), "chart:argo-cd", "10.x"),
        ("platform/a.yaml", APPLICATION.format(version="'>=10'"), "chart:argo-cd", ">=10"),
        ("services/x/Dockerfile", "FROM nginx\n", "image:nginx", ""),
        ("platform/a.yaml", "  image: reg.io:5000/app:latest\n", "image:reg.io:5000/app", "latest"),
        ("platform/a.yaml", "  tag: main\n", "image-tag:platform/a.yaml", "main"),
        ("scripts/a.sh", "  export INGRESS_NGINX_CHART_VERSION=latest\n", "chart:ingress-nginx", "latest"),
    ],
)
def test_guard_sees_floating_forms(path: str, text: str, component: str, version: str) -> None:
    assert violations(collect_pins({path: text})) == {component: [version]}


def test_guard_ignores_build_stages_and_reads_commented_versions() -> None:
    files = {
        "services/x/Dockerfile": "FROM node:24.1.0 AS build\nFROM build\nFROM scratch\n",
        ".github/workflows/a.yml": "  node-version: 20 # lts\n",
        ".github/workflows/b.yml": "  node-version: 22\n",
    }
    assert violations(collect_pins(files)) == {"ci:node-version": ["20", "22"]}


def test_guard_sees_installs_with_no_version() -> None:
    files = {
        "infra/a.sh": "helm upgrade --install jenkins jenkins/jenkins \\\n  --namespace x\n"
        'helm upgrade --install backstage backstage/backstage --version "1.0.0"\n'
        'helm upgrade --install local "$ROOT/charts/local"\n'
        "kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml\n",
        "infra/b.yaml": '          image: "docker.com/paruff/fawkesproxy"\n',
    }
    assert violations(collect_pins(files)) == {
        "chart:jenkins": [""],
        "url:argoproj/argo-cd": ["stable"],
        "image:docker.com/paruff/fawkesproxy": [""],
    }


def test_guard_compares_trivy_image_with_ci_install() -> None:
    files = {
        "templates/a.yaml": "      image: docker.io/aquasec/trivy:0.74.0\n",
        ".github/workflows/s.yml": "      uses: aquasecurity/setup-trivy@abc # v0.3.1\n"
        "        with:\n          # note\n          version: v0.73.0\n",
    }
    assert violations(collect_pins(files)) == {"tool:trivy": ["v0.73.0", "v0.74.0"]}
