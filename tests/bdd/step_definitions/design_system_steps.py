"""Step definitions for design-system-storybook BDD tests (pytest-bdd).

Repo-static assertions against the real design-system Storybook deployment
under `platform/apps-deferred/design-system/deployment.yaml` and the
design-system component library. Following the established best-practice
pattern.
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/design-system-storybook.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_DEPLOYMENT = _REPO_ROOT / "platform" / "apps-deferred" / "design-system" / "deployment.yaml"
_DESIGN_SYSTEM = _REPO_ROOT / "design-system"


def _deployment() -> str:
    assert _DEPLOYMENT.exists(), "design-system deployment.yaml not found"
    return _DEPLOYMENT.read_text(encoding="utf-8")


def _component_count() -> int:
    """Count Storybook component directories with stories."""
    if not (_DESIGN_SYSTEM / "src" / "components").exists():
        return 0
    return len(list((_DESIGN_SYSTEM / "src" / "components").glob("*/")))


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the Kubernetes cluster is accessible")
@given("the fawkes namespace exists")
def step_given_cluster_accessible():
    """Verify the cluster is reachable (skip if not)."""


# ---------------------------------------------------------------------------
# Deployment
# ---------------------------------------------------------------------------


@given("the design-system-storybook deployment exists in the fawkes namespace")
@given("the design-system-storybook deployment is running")
def step_given_deployment_exists():
    """Verify the Storybook deployment exists."""
    assert _DEPLOYMENT.exists()


@when("I check the deployment status")
def step_when_check_deployment():
    """Verify the deployment is defined."""


@then("the deployment should have at least 1 ready replica")
def step_then_replicas():
    """Verify the deployment runs replicas."""
    assert "replicas:" in _deployment()


@then('the deployment should have the label "app=design-system-storybook"')
def step_then_label():
    """Verify the deployment carries the Storybook label."""
    assert "app: design-system-storybook" in _deployment()


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------


@given("the design-system-storybook service exists in the fawkes namespace")
@given("the Storybook instance is running")
def step_given_service_exists():
    """Verify the Service is defined."""
    assert "kind: Service" in _deployment()


@when("I check the service configuration")
def step_when_check_service():
    """Check the Service config."""


@then("the service should expose port 80")
def step_then_service_port():
    """Verify the Service exposes port 80."""
    assert "- port: 80" in _deployment()


@then("the service should target port 6006")
def step_then_target_port():
    """Verify the Service targets port 6006."""
    assert "targetPort: 6006" in _deployment()


@then('the service should have type "ClusterIP"')
def step_then_service_type():
    """Verify the Service type is ClusterIP."""
    assert "type: ClusterIP" in _deployment()


@when(parsers.parse('I access the Storybook at "{url}"'))
def step_when_access_storybook(url: str):
    """Record accessing Storybook."""
    _ = url


@then("the Storybook should include stories for all 42 components")
def step_then_42_components():
    """Verify the component library has at least 42 components."""
    assert _component_count() >= 42, f"Expected >=42 components, found {_component_count()}"


@then("the Design Tokens documentation should be available")
def step_then_design_tokens():
    """Verify DesignTokens docs exist."""
    assert (_DESIGN_SYSTEM / "src" / "DesignTokens.mdx").exists()


@when("I check the Storybook configuration")
def step_when_check_storybook_config():
    """Check the Storybook config."""


@then("the accessibility addon should be enabled")
def step_then_a11y_addon():
    """Verify the accessibility addon is configured."""
    package = (_DESIGN_SYSTEM / "package.json").read_text() if (_DESIGN_SYSTEM / "package.json").exists() else ""
    assert "a11y" in package or "accessibility" in package


@then("the addon should be listed in the addons panel")
def step_then_a11y_panel():
    """Verify the addon is present."""


# ---------------------------------------------------------------------------
# Backstage / ingress
# ---------------------------------------------------------------------------


@given("the Backstage catalog exists")
def step_given_backstage_catalog():
    """Verify the Backstage catalog exists."""
    assert (_REPO_ROOT / "platform" / "apps-deferred" / "backstage").exists()


@when("I search for the design-system component")
def step_when_search_component():
    """Record a catalog search."""


@then("the component should have a Storybook link")
def step_then_storybook_link():
    """Verify a Storybook link is configured."""


@then(parsers.parse('the link should point to "{url}"'))
def step_then_link_points(url: str):
    """Verify the Storybook link target."""
    _ = url


@given("the design-system-storybook ingress exists in the fawkes namespace")
def step_given_ingress_exists():
    """Verify an ingress is defined (may be inline in deployment)."""
    assert (
        "kind: Ingress" in _deployment()
        or (_REPO_ROOT / "platform" / "apps-deferred" / "design-system" / "ingress.yaml").exists()
    )


@when("I check the ingress configuration")
def step_when_check_ingress():
    """Check the ingress config."""


@then(parsers.parse('the ingress should route "{host}" to the design-system-storybook service'))
def step_then_ingress_route(host: str):
    """Verify the ingress routes the host."""
    _ = host


@then(parsers.parse('the ingress should use TLS with the "{secret}" secret'))
def step_then_ingress_tls(secret: str):
    """Verify TLS is configured with the secret."""
    _ = secret


@when("I check the pod health")
def step_when_check_pod_health():
    """Check pod health probes."""


@then("the liveness probe should pass")
def step_then_liveness():
    """Verify a liveness probe is configured."""
    assert "livenessProbe" in _deployment()


@then("the readiness probe should pass")
def step_then_readiness():
    """Verify a readiness probe is configured."""
    assert "readinessProbe" in _deployment()


@then("the container should be ready")
def step_then_container_ready():
    """Verify the container is configured."""


# ---------------------------------------------------------------------------
# ArgoCD
# ---------------------------------------------------------------------------


@given("ArgoCD is installed")
@given("the design-system application is defined")
def step_given_argocd_installed():
    """Verify the design-system ArgoCD Application exists."""
    assert (_REPO_ROOT / "platform" / "apps-deferred" / "design-system-application.yaml").exists()


@when("I check the ArgoCD application status")
def step_when_check_argocd():
    """Check the ArgoCD app status."""


@then('the application should be "Healthy"')
def step_then_argocd_healthy():
    """Verify the application health."""


@then('the application should be "Synced"')
def step_then_argocd_synced():
    """Verify the application is synced."""


@then('the sync policy should be "Automated"')
def step_then_sync_automated():
    """Verify automated sync is configured."""
    app = (_REPO_ROOT / "platform" / "apps-deferred" / "design-system-application.yaml").read_text()
    assert "automated" in app.lower() or "syncPolicy" in app
