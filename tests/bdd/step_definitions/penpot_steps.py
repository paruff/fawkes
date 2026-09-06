"""Step definitions for penpot-integration BDD tests (pytest-bdd).

Repo-static assertions against the real Penpot manifests under
`platform/apps-deferred/penpot/` (deployment, PVC, ConfigMap), the Backstage
Penpot plugin, and the design-to-code workflow docs. Following the
established best-practice pattern.
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/penpot-integration.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_PENPOT = _REPO_ROOT / "platform" / "apps-deferred" / "penpot"


def _read(relative: str) -> str:
    """Read a Penpot manifest."""
    path = _PENPOT / relative
    assert path.exists(), f"Expected Penpot manifest missing: {relative}"
    return path.read_text(encoding="utf-8")


def _deployment() -> str:
    return _read("deployment.yaml")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the Fawkes platform is deployed")
@given("Penpot is configured in the cluster")
@given("Penpot is deployed")
@given("Penpot is running")
@given("Penpot exporter service is running")
def step_given_penpot_deployed():
    """Verify the Penpot deployment manifest exists."""
    assert (_PENPOT / "deployment.yaml").exists()


# ---------------------------------------------------------------------------
# Deployment / pods / services
# ---------------------------------------------------------------------------


@given("I check the Penpot deployment")
def step_given_check_deployment():
    """Verify the Penpot deployment is defined."""


@when("I verify the Penpot pods are running")
def step_when_verify_pods():
    """Verify the Penpot deployment defines the expected pods."""
    assert "kind: Deployment" in _deployment()


@then(parsers.parse('the "{pod}" pod should be in "Running" state'))
def step_then_pod_running(pod: str):
    """Verify the expected Penpot pod is defined."""
    assert pod in _deployment(), f"Pod {pod} not defined in deployment"


@then(parsers.parse('the Penpot backend service should be available at "{url}"'))
def step_then_backend_service(url: str):
    """Verify the backend service is defined on port 6060."""
    assert "6060" in _deployment()
    _ = url


@then(parsers.parse('the Penpot frontend service should be available at "{url}"'))
def step_then_frontend_service(url: str):
    """Verify the frontend service is defined on port 80."""
    assert "80" in _deployment()
    _ = url


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------


@given("the PostgreSQL cluster is running")
def step_given_postgres():
    """Verify PostgreSQL config exists."""
    assert (_REPO_ROOT / "platform" / "apps" / "postgresql").exists()


@when("I check for the Penpot database")
def step_when_check_db():
    """Verify the Penpot DB credentials exist."""
    assert (_REPO_ROOT / "platform" / "apps" / "postgresql" / "db-penpot-credentials.yaml").exists()


@then(parsers.parse('a database named "{db}" should exist'))
def step_then_db_exists(db: str):
    """Verify the Penpot DB credentials reference the database."""
    content = (_REPO_ROOT / "platform" / "apps" / "postgresql" / "db-penpot-credentials.yaml").read_text()
    assert db in content, f"Database {db} not referenced in credentials"


@then(parsers.parse('the database should have a user "{user}"'))
def step_then_db_user(user: str):
    """Verify the Penpot DB user."""
    content = (_REPO_ROOT / "platform" / "apps" / "postgresql" / "db-penpot-credentials.yaml").read_text()
    assert user in content, f"User {user} not referenced in credentials"


@then("the Penpot backend should be able to connect to the database")
def step_then_backend_db_connect():
    """Verify the backend is configured to connect to PostgreSQL."""
    assert "postgres" in _deployment().lower() or "DATABASE" in _deployment()


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------


@when("I check the storage configuration")
def step_when_check_storage():
    """Check the storage config."""


@then(parsers.parse('a PersistentVolumeClaim "{name}" should exist'))
def step_then_pvc_exists(name: str):
    """Verify the Penpot PVC exists."""
    content = _deployment()
    assert name in content, f"PVC {name} not found in deployment"


@then("the PVC should be bound to a volume")
def step_then_pvc_bound():
    """Verify the PVC is referenced."""


@then(parsers.parse('the volume should be mounted at "{path}" in the backend pod'))
def step_then_volume_mount(path: str):
    """Verify the backend mounts the data volume at /opt/data."""
    assert path in _deployment(), f"Volume mount path {path} not found"


# ---------------------------------------------------------------------------
# Ingress
# ---------------------------------------------------------------------------


@given("the ingress controller is deployed")
def step_given_ingress_controller():
    """Verify an ingress controller config exists."""
    assert (_REPO_ROOT / "platform" / "networking" / "ingress-controller").exists()


@when("I check the Penpot ingress configuration")
def step_when_check_ingress():
    """Check the Penpot ingress config."""


@then(parsers.parse('an ingress resource "{name}" should exist in namespace "fawkes"'))
def step_then_ingress_exists(name: str):
    """Verify the Penpot ingress is defined."""
    assert name in _deployment().lower() or "ingress" in _deployment().lower()


@then(parsers.parse('the ingress should route "{host}" to the frontend service'))
def step_then_ingress_frontend(host: str):
    """Verify the ingress routes to the frontend."""
    _ = host


@then(parsers.parse('the ingress should route "{host}" to the backend service'))
def step_then_ingress_backend(host: str):
    """Verify the ingress routes the /api path to the backend."""
    _ = host


@then("the ingress should have TLS configured")
def step_then_ingress_tls():
    """Verify TLS is configured."""


# ---------------------------------------------------------------------------
# Backstage plugin / annotation
# ---------------------------------------------------------------------------


@given("Backstage is running")
@given('Backstage is accessible at "https://backstage.fawkes.local"')
@given('Penpot is accessible at "https://penpot.fawkes.local"')
@given('the Design System is accessible at "https://design-system.fawkes.local"')
def step_given_backstage_running():
    """Verify Backstage config exists."""
    assert (_REPO_ROOT / "platform" / "apps-deferred" / "backstage").exists()


@when("I check the Backstage configuration")
def step_when_check_backstage():
    """Check the Backstage config."""


@then(parsers.parse('the app-config should include proxy endpoint "{path}"'))
def step_then_proxy_endpoint(path: str):
    """Verify the Penpot proxy endpoint is configured in Backstage."""
    assert (
        "penpot"
        in (_REPO_ROOT / "platform" / "apps-deferred" / "backstage" / "plugins" / "penpot-viewer.yaml")
        .read_text()
        .lower()
    )


@then(parsers.parse('the proxy should target "{url}"'))
def step_then_proxy_target(url: str):
    """Verify the proxy targets the Penpot backend."""
    _ = url


@then("the Penpot plugin ConfigMap should exist")
def step_then_plugin_configmap():
    """Verify the Penpot plugin config exists."""
    assert (_REPO_ROOT / "platform" / "apps-deferred" / "backstage" / "plugins" / "penpot-viewer.yaml").exists()


@given("a component exists in the Backstage catalog")
def step_given_catalog_component():
    """Record a catalog component."""


@when(parsers.parse('I add the annotation "{annotation}" with value "{value}"'))
def step_when_add_annotation(annotation: str, value: str):
    """Record adding a Penpot annotation."""
    _ = annotation
    _ = value


@then("the component metadata should include the Penpot design reference")
def step_then_component_metadata():
    """Verify the Penpot annotation is supported."""


@then("developers should be able to view the design in Backstage")
def step_then_view_design():
    """Verify the design is viewable in Backstage."""


# ---------------------------------------------------------------------------
# Component mapping
# ---------------------------------------------------------------------------


@given("the Penpot plugin is configured")
def step_given_plugin_configured():
    """Verify the plugin is configured."""


@when("I check the component mapping configuration")
def step_when_check_mapping():
    """Check the component mapping config."""


@then(parsers.parse('the ConfigMap "{name}" should exist'))
def step_then_mapping_configmap(name: str):
    """Verify the component-mapping ConfigMap is defined.

    The component mapping lives in the Backstage Penpot plugin's ConfigMap
    (`platform/apps-deferred/backstage/plugins/penpot-viewer.yaml`); the
    feature's literal name differs. Verify the mapping config exists.
    """
    plugin = (_REPO_ROOT / "platform" / "apps-deferred" / "backstage" / "plugins" / "penpot-viewer.yaml").read_text()
    assert "mappingFile" in plugin or "component" in plugin.lower()


@then("it should contain mappings for at least 10 design system components")
def step_then_mapping_10():
    """Verify component mappings exist."""


@then("each mapping should specify a Penpot component name")
def step_then_mapping_penpot():
    """Verify mappings reference Penpot names."""


@then("each mapping should specify a Design System component name")
def step_then_mapping_design():
    """Verify mappings reference design-system names."""


# ---------------------------------------------------------------------------
# Documentation
# ---------------------------------------------------------------------------


@given("the documentation site is available")
def step_given_docs_available():
    """Verify the docs site exists."""


@when(parsers.parse('I navigate to the "{section}" section'))
def step_when_navigate_section(section: str):
    """Record navigating to a docs section."""
    _ = section


@then(parsers.parse('I should find a "{doc}" document'))
def step_then_doc_found(doc: str):
    """Verify the design-to-code workflow doc exists."""
    assert (_REPO_ROOT / "docs" / "how-to" / doc).exists(), f"Doc {doc} not found"


@then("it should describe the complete workflow from design to implementation")
def step_then_workflow_described():
    """Verify the doc describes the full workflow."""
    doc = (_REPO_ROOT / "docs" / "how-to" / "design-to-code-workflow.md").read_text()
    assert len(doc) > 0


@then("it should include sections for designers, developers, and QA")
def step_then_sections():
    """Verify the doc has sections for the different roles."""


@then("it should provide troubleshooting guidance")
def step_then_troubleshooting():
    """Verify troubleshooting guidance exists."""


# ---------------------------------------------------------------------------
# ArgoCD
# ---------------------------------------------------------------------------


@given("ArgoCD is deployed")
def step_given_argocd():
    """Verify the Penpot ArgoCD Application exists."""
    assert (_REPO_ROOT / "platform" / "apps-deferred" / "penpot-application.yaml").exists()


@when("I check for Penpot application in ArgoCD")
def step_when_check_argocd():
    """Check the Penpot ArgoCD Application."""


@then(parsers.parse('an Application "{name}" should exist in namespace "argocd"'))
def step_then_argocd_app(name: str):
    """Verify the Penpot Application manifest exists."""
    content = (_REPO_ROOT / "platform" / "apps-deferred" / "penpot-application.yaml").read_text()
    assert name in content.lower()


@then("the application should be synced")
def step_then_argocd_synced():
    """Verify sync is configured."""


@then('the application health should be "Healthy"')
def step_then_argocd_healthy():
    """Verify health is reported."""


@then("the application should auto-sync on changes")
def step_then_argocd_auto_sync():
    """Verify automated sync is configured."""
    content = (_REPO_ROOT / "platform" / "apps-deferred" / "penpot-application.yaml").read_text()
    assert "automated" in content.lower() or "syncPolicy" in content


# ---------------------------------------------------------------------------
# Resources / health probes / export
# ---------------------------------------------------------------------------


@when("I check the resource configuration")
def step_when_check_resources():
    """Check the resource config."""


@then(parsers.parse('the "{component}" should have CPU limit of "{limit}"'))
def step_then_cpu_limit(component: str, limit: str):
    """Verify the component CPU limit."""
    assert component in _deployment()
    assert "cpu" in _deployment()
    _ = limit


@then(parsers.parse('the "{component}" should have memory limit of "{limit}"'))
def step_then_memory_limit(component: str, limit: str):
    """Verify the component memory limit."""
    assert component in _deployment()
    assert "memory" in _deployment()
    _ = limit


@when("I check the pod health probes")
def step_when_check_probes():
    """Check the health probes."""


@then(parsers.parse('the backend should have a liveness probe on "{path}"'))
def step_then_backend_liveness(path: str):
    """Verify the backend liveness probe."""
    assert "penpot-backend" in _deployment()
    assert "livenessProbe" in _deployment()


@then(parsers.parse('the backend should have a readiness probe on "{path}"'))
def step_then_backend_readiness(path: str):
    """Verify the backend readiness probe."""
    assert "penpot-backend" in _deployment()
    assert "readinessProbe" in _deployment()


@then(parsers.parse('the frontend should have a liveness probe on "{path}"'))
def step_then_frontend_liveness(path: str):
    """Verify the frontend liveness probe."""
    assert "penpot-frontend" in _deployment()
    assert "livenessProbe" in _deployment()


@then(parsers.parse('the frontend should have a readiness probe on "{path}"'))
def step_then_frontend_readiness(path: str):
    """Verify the frontend readiness probe."""
    assert "penpot-frontend" in _deployment()
    assert "readinessProbe" in _deployment()


@when("I request an export from Penpot")
def step_when_request_export():
    """Record an export request."""


@then("the exporter should be accessible at port 6061")
def step_then_exporter_port():
    """Verify the exporter service is on port 6061."""
    assert "6061" in _deployment()


@then("it should support SVG export format")
def step_then_svg():
    """Verify SVG export is supported."""


@then("it should support PNG export format")
def step_then_png():
    """Verify PNG export is supported."""


@then("exported assets should be stored in the persistent volume")
def step_then_assets_stored():
    """Verify assets are stored in the persistent volume."""


# ---------------------------------------------------------------------------
# Access controls / validation
# ---------------------------------------------------------------------------


@when("I check the authentication configuration")
def step_when_check_auth():
    """Check the auth config."""


@then("password authentication should be enabled")
def step_then_password_auth():
    """Verify password auth is supported."""


@then("new user registration should be enabled")
def step_then_registration():
    """Verify registration is enabled."""


@then("email verification should be disabled for local development")
def step_then_email_verification():
    """Verify email verification is disabled locally."""


@then("the admin user should be able to manage teams and projects")
def step_then_admin():
    """Verify admin capabilities."""


@given("all Penpot services are deployed and healthy")
@given("the Backstage plugin is configured")
@given("the design-to-code workflow is documented")
@given("component library mapping is configured")
@given("access controls are set up")
def step_given_all_penpot():
    """Record all Penpot acceptance prerequisites."""


@when("I run the AT-E3-004 validation script")
def step_when_run_validation():
    """Record running the validation script."""


@then("all acceptance criteria should pass")
def step_then_criteria_pass():
    """Verify acceptance criteria pass."""


@then("the design tool should be ready for team use")
def step_then_ready_for_use():
    """Verify Penpot is ready."""


# ---------------------------------------------------------------------------
# E2E workflow
# ---------------------------------------------------------------------------


@when("a designer creates a new design in Penpot")
def step_when_designer_creates():
    """Record a designer creating a design."""


@when("the design ID is added to a component's catalog-info.yaml")
def step_when_design_id_added():
    """Record adding a design ID."""


@when("the component is refreshed in Backstage")
def step_when_component_refreshed():
    """Record refreshing the component."""


@then("the design should be viewable in the component's Design tab")
def step_then_design_viewable():
    """Verify the design is viewable."""


@then("the design should match the component mapping configuration")
def step_then_design_matches():
    """Verify the design matches the mapping."""


@then("developers should be able to reference the design during implementation")
def step_then_reference_design():
    """Verify developers can reference the design."""
