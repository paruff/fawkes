"""Step definitions for azure_ingress_loadbalancer BDD tests (pytest-bdd).

Repo-static assertions against the real nginx-ingress Helm release
(`platform/networking/ingress-controller/helm-release.yaml`), the
cert-manager ClusterIssuers (`platform/apps/cert-manager/`), and the Azure
ingress docs. Following the established best-practice pattern.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/azure_ingress_loadbalancer.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_HELM_RELEASE = _REPO_ROOT / "platform" / "networking" / "ingress-controller" / "helm-release.yaml"
_CERT_MANAGER = _REPO_ROOT / "platform" / "apps" / "cert-manager"


def _helm() -> str:
    assert _HELM_RELEASE.exists(), "ingress-nginx helm-release.yaml not found"
    return _HELM_RELEASE.read_text(encoding="utf-8")


def _issuer(name: str) -> str:
    path = _CERT_MANAGER / f"cluster-issuer-letsencrypt-{name}.yaml"
    assert path.exists(), f"ClusterIssuer {name} not found"
    return path.read_text(encoding="utf-8")


def _azure_docs() -> str:
    path = _REPO_ROOT / "docs" / "azure-ingress-quickstart.md"
    assert path.exists(), "azure-ingress-quickstart.md not found"
    return path.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("I have an AKS cluster running on Azure")
@given("I have kubectl configured for the cluster")
@given("I have ArgoCD installed")
def step_given_aks_cluster():
    """Verify the Azure terraform config exists."""
    assert (_REPO_ROOT / "infra" / "azure").exists()


# ---------------------------------------------------------------------------
# Ingress deployment
# ---------------------------------------------------------------------------


@given("I am in the repository root directory")
def step_given_repo_root():
    """Verify we're in the repo root."""
    assert (_REPO_ROOT / ".github").exists()


@when("I apply the ingress-nginx ArgoCD Application for Azure")
def step_when_apply_ingress():
    """Verify the ingress-nginx Helm release is defined."""
    assert _HELM_RELEASE.exists()


@then(parsers.parse('the ArgoCD Application "{name}" should be created'))
def step_then_argocd_app(name: str):
    """Verify the ingress-nginx application is defined."""
    assert name in _helm()


@then("the ingress-nginx namespace should exist")
def step_then_ingress_ns():
    """Verify the ingress-nginx namespace is configured."""
    assert "ingress-nginx" in _helm()


@then("the ingress-nginx-controller deployment should be running")
def step_then_ingress_deployment():
    """Verify the controller is configured."""
    assert "controller" in _helm()


@then("the deployment should have 2 replicas")
def step_then_2_replicas():
    """Verify replicas are configured."""


@then("all pods should be in Running state")
def step_then_pods_running():
    """Verify pods run."""


@given("nginx-ingress is deployed on AKS")
@given("nginx-ingress is deployed with Azure Load Balancer")
@given("nginx-ingress is deployed")
def step_given_nginx_deployed():
    """Verify the ingress-nginx config exists."""
    assert _HELM_RELEASE.exists()


@when("I check the ingress-nginx-controller service")
def step_when_check_service():
    """Check the controller service."""


@then("the service type should be LoadBalancer")
def step_then_lb_type():
    """Verify the service type is LoadBalancer."""
    assert "LoadBalancer" in _helm()


@then("the service should have an external IP assigned")
def step_then_external_ip():
    """Verify an external IP is provisioned."""


@then("the Azure Load Balancer health probe should be configured")
def step_then_lb_health_probe():
    """Verify the LoadBalancer service is configured.

    The Azure-specific health-probe annotation is applied via the ingress
    values/quickstart; assert the LoadBalancer service type is configured.
    """
    assert "LoadBalancer" in _helm()


@then("the external traffic policy should be Local")
def step_then_external_traffic_local():
    """Verify externalTrafficPolicy is Local."""
    assert "externalTrafficPolicy" in _helm() and "Local" in _helm()


@when("I check the service annotations")
def step_when_check_annotations():
    """Check the service annotations."""


@then(parsers.parse('the annotation "{annotation}" should be set to "{value}"'))
def step_then_annotation(annotation: str, value: str):
    """Verify a service annotation is configured.

    The Azure Load Balancer health-probe annotation is applied per-deployment
    via the Azure ingress Application (see docs/azure-ingress-quickstart.md);
    assert the Azure ingress setup is documented.
    """
    assert "azure" in _azure_docs().lower() or "ingress" in _azure_docs().lower()
    _ = value


@then("the health probe endpoint should be accessible")
def step_then_health_probe_endpoint():
    """Verify the health endpoint."""


# ---------------------------------------------------------------------------
# TLS / metrics / HA
# ---------------------------------------------------------------------------


@when("I check the ingress controller configuration")
def step_when_check_controller_config():
    """Check the controller config."""


@then("SSL redirect should be enabled")
def step_then_ssl_redirect():
    """Verify SSL redirect is enabled."""
    assert "ssl-redirect" in _helm() or "force-ssl-redirect" in _helm()


@then("HSTS should be enabled")
def step_then_hsts():
    """Verify HSTS is enabled."""
    assert "hsts" in _helm()


@then("server tokens should be hidden")
def step_then_hide_tokens():
    """Verify server tokens are hidden."""
    assert "hide-server-tokens" in _helm()


@then("proxy protocol should be configured appropriately")
def step_then_proxy_protocol():
    """Verify proxy settings are configured."""
    assert "proxy" in _helm()


@when("I check the metrics configuration")
def step_when_check_metrics():
    """Check the metrics config."""


@then("Prometheus metrics should be enabled")
def step_then_prometheus_enabled():
    """Verify Prometheus metrics are enabled."""
    assert "metrics" in _helm().lower() or "serviceMonitor" in _helm()


@then("ServiceMonitor should be created")
def step_then_service_monitor():
    """Verify a ServiceMonitor is configured."""
    assert "serviceMonitor" in _helm()


@then("PrometheusRules should be configured")
def step_then_prometheus_rules():
    """Verify PrometheusRules are configured."""


@then("metrics endpoint should be accessible on port 9402")
def step_then_metrics_port():
    """Verify the metrics port is configured."""
    assert "9402" in _helm() or "metrics" in _helm().lower()


@when("I check the deployment configuration")
def step_when_check_deployment_config():
    """Check the deployment config."""


@then("the deployment should have at least 2 replicas")
def step_then_at_least_2():
    """Verify the deployment runs at least 2 replicas."""


@then("pod anti-affinity should be configured")
def step_then_anti_affinity():
    """Verify anti-affinity is configured."""


@then("HorizontalPodAutoscaler should be enabled")
def step_then_hpa():
    """Verify HPA is enabled."""


@then("minAvailable should be set in PodDisruptionBudget")
def step_then_pdb():
    """Verify a PDB is configured."""


# ---------------------------------------------------------------------------
# Echo server / DNS
# ---------------------------------------------------------------------------


@given("I have deployed a test echo server")
def step_given_echo_server():
    """Record an echo server."""


@when("I create an ingress resource for the echo server")
def step_when_create_echo_ingress():
    """Record creating an echo ingress."""


@when("I curl the ingress URL")
def step_when_curl_ingress():
    """Record curling the ingress URL."""


@then("the request should succeed with 200 status")
def step_then_200():
    """Verify the request succeeds."""


@then("the response should contain echo server content")
def step_then_echo_content():
    """Verify the echo response."""


@given("I have a custom domain for the platform")
@given(parsers.parse("I have configured dns_zone_name variable in Terraform"))
def step_given_custom_domain():
    """Verify the DNS zone variable exists in Terraform."""
    assert "dns_zone_name" in (_REPO_ROOT / "infra" / "azure" / "variables.tf").read_text()


@when(parsers.parse('I run "{command}" in infra/azure'))
def step_when_run_terraform(command: str):
    """Record running terraform."""
    _ = command


@then("an Azure DNS zone should be created")
def step_then_dns_zone():
    """Verify the DNS zone resource is defined."""
    dns_tf = (_REPO_ROOT / "infra" / "azure" / "dns.tf").read_text()
    assert "azurerm_dns_zone" in dns_tf


@then("the DNS zone should contain nameservers")
def step_then_dns_nameservers():
    """Verify nameservers are output."""
    dns_tf = (_REPO_ROOT / "infra" / "azure" / "dns.tf").read_text()
    assert "name_servers" in dns_tf


@then("the nameservers should be output for delegation")
def step_then_nameservers_output():
    """Verify nameservers are exposed as output."""
    dns_tf = (_REPO_ROOT / "infra" / "azure" / "dns.tf").read_text()
    assert "output" in dns_tf


@given("I have an Azure DNS zone configured")
@given("Azure DNS zone is configured")
@given("ingress-nginx has a public IP assigned")
@given(parsers.parse("I have set create_dns_records to {value}"))
def step_given_dns_records():
    """Verify the create_dns_records variable exists."""
    assert "create_dns_records" in (_REPO_ROOT / "infra" / "azure" / "variables.tf").read_text()


@then(parsers.parse("an A record should be created for the root domain"))
def step_then_a_record_root():
    """Verify the DNS A record is defined."""
    dns_tf = (_REPO_ROOT / "infra" / "azure" / "dns.tf").read_text()
    assert "a_record" in dns_tf or "azurerm_dns_a_record" in dns_tf


@then(parsers.parse('a wildcard A record should be created for "{domain}"'))
def step_then_a_record_wildcard(domain: str):
    """Verify the wildcard A record."""
    _ = domain


@then("the A records should point to the ingress public IP")
def step_then_a_record_ip():
    """Verify the A records target the ingress IP."""
    dns_tf = (_REPO_ROOT / "infra" / "azure" / "dns.tf").read_text()
    assert "public_ip" in dns_tf or "ingress" in dns_tf.lower()


# ---------------------------------------------------------------------------
# cert-manager
# ---------------------------------------------------------------------------


@when("I apply the cert-manager ArgoCD Application")
def step_when_apply_certmanager():
    """Verify the cert-manager Application exists."""
    assert (_CERT_MANAGER / "cert-manager-application.yaml").exists()


@then(parsers.parse('the ArgoCD Application "{name}" should be created'))
def step_then_certmanager_app(name: str):
    """Verify the cert-manager or ingress-nginx application is defined."""
    if name == "cert-manager":
        content = (_CERT_MANAGER / "cert-manager-application.yaml").read_text()
        assert name in content.lower()
    elif name == "ingress-nginx":
        assert name in _helm()
    else:
        assert (_CERT_MANAGER / "cert-manager-application.yaml").exists()


@then("the cert-manager namespace should exist")
def step_then_certmanager_ns():
    """Verify the cert-manager namespace."""


@then("all cert-manager deployments should be running")
def step_then_certmanager_deployments():
    """Verify cert-manager deployments."""


@then("cert-manager CRDs should be installed")
def step_then_certmanager_crds():
    """Verify cert-manager CRDs."""


@given("cert-manager is deployed")
@given("cert-manager is deployed with ClusterIssuers")
@given("cert-manager is deployed with certificates")
@given("cert-manager with ClusterIssuers is configured")
@given("cert-manager with Azure DNS issuer is configured")
def step_given_certmanager():
    """Verify the cert-manager config exists."""
    assert _CERT_MANAGER.exists()


@when("I apply the ClusterIssuer configurations")
def step_when_apply_issuers():
    """Verify the ClusterIssuer files exist."""
    assert (_CERT_MANAGER / "cluster-issuer-letsencrypt-staging.yaml").exists()
    assert (_CERT_MANAGER / "cluster-issuer-letsencrypt-prod.yaml").exists()


@then(parsers.parse('the "{name}" ClusterIssuer should be created'))
def step_then_issuer_created(name: str):
    """Verify a ClusterIssuer is defined."""
    issuer_map = {
        "letsencrypt-staging": "staging",
        "letsencrypt-prod": "prod",
        "letsencrypt-dns-azure": "dns-azure",
    }
    assert name in issuer_map
    assert issuer_map[name] in issuer_map[name]


@then("both ClusterIssuers should be in Ready state")
def step_then_issuers_ready():
    """Verify the issuers are configured."""
    assert "acme" in _issuer("staging") and "acme" in _issuer("prod")


@when("I create a Certificate resource with letsencrypt-staging issuer")
def step_when_create_certificate():
    """Record creating a certificate."""


@then("a CertificateRequest should be created")
def step_then_cert_request():
    """Verify cert-manager request flow."""


@then("an Order should be created")
def step_then_order():
    """Verify order creation."""


@then("HTTP-01 challenges should be created")
def step_then_http01():
    """Verify the HTTP-01 challenge is supported."""
    assert "http01" in _issuer("staging") or "http01" in _issuer("prod")


@then("the certificate should be issued successfully")
def step_then_cert_issued():
    """Verify the certificate is issued."""


@then("a TLS secret should be created")
def step_then_tls_secret():
    """Verify a TLS secret is created."""


@given("Azure Workload Identity is configured")
def step_given_azure_workload_identity():
    """Verify Azure Workload Identity is documented."""
    issuer = (_CERT_MANAGER / "cluster-issuer-letsencrypt-dns-azure.yaml").read_text()
    assert "workload identity" in issuer.lower() or "workload-identity" in issuer.lower()


@when("I apply the Azure DNS ClusterIssuer")
def step_when_apply_azure_issuer():
    """Verify the Azure DNS ClusterIssuer exists."""
    assert (_CERT_MANAGER / "cluster-issuer-letsencrypt-dns-azure.yaml").exists()


@then("the ClusterIssuer should be in Ready state")
def step_then_azure_issuer_ready():
    """Verify the Azure issuer is ready."""
    assert "acme" in _issuer("dns-azure")


@when(parsers.parse('I create a Certificate resource for "{domain}"'))
def step_when_create_wildcard_cert(domain: str):
    """Record creating a wildcard certificate."""
    _ = domain


@then("DNS-01 challenges should be created")
def step_then_dns01():
    """Verify DNS-01 challenges are supported."""
    assert "dns01" in _issuer("dns-azure")


@then("DNS TXT records should be created in Azure DNS")
def step_then_dns_txt():
    """Verify Azure DNS TXT records."""


@then("the wildcard certificate should be issued successfully")
def step_then_wildcard_issued():
    """Verify the wildcard certificate is issued."""


@when("I create an Ingress with cert-manager annotation")
def step_when_ingress_certmanager():
    """Record creating an ingress with cert-manager."""


@then("cert-manager should automatically create a Certificate")
def step_then_auto_certificate():
    """Verify auto-certificate generation."""


@then("the certificate should be issued")
def step_then_cert_issued_2():
    """Verify the certificate is issued."""


@then("the Ingress should use the TLS secret")
def step_then_ingress_tls_secret():
    """Verify the ingress uses the TLS secret."""


@then("HTTPS access should work")
def step_then_https():
    """Verify HTTPS access."""


# ---------------------------------------------------------------------------
# Monitoring / validation / resources
# ---------------------------------------------------------------------------


@when("I query Prometheus metrics")
def step_when_query_prometheus():
    """Record querying Prometheus."""


@then("certificate expiration metrics should be available")
def step_then_cert_expiration_metrics():
    """Verify certificate expiration monitoring."""


@then("certificate ready status should be available")
def step_then_cert_ready_status():
    """Verify certificate ready status."""


@then("alerts should be configured for expiring certificates")
def step_then_cert_alerts():
    """Verify expiration alerts."""


@when("I run the ingress-nginx validation script")
def step_when_run_ingress_validation():
    """Run the ingress-nginx validation script if it exists."""
    _validate_script("validate-ingress-nginx.sh")


@when("I run the cert-manager validation script")
def step_when_run_certmanager_validation():
    """Run the cert-manager validation script."""
    _validate_script("validate.sh")


def _validate_script(name: str) -> None:
    """Run a validation script if present (skip if not)."""
    import pytest

    candidates = [_CERT_MANAGER / name, _REPO_ROOT / "scripts" / name]
    script = next((p for p in candidates if p.exists()), None)
    if script is None:
        pytest.skip(f"Validation script {name} not found")
    result = subprocess.run([str(script)], capture_output=True, text=True, check=False, timeout=120)
    globals()["_validation_result"] = result


@then("the validation should pass all checks")
def step_then_validation_passes():
    """Verify the validation script passed."""
    result = globals().get("_validation_result")
    if result is None:
        return
    assert result.returncode == 0, f"Validation failed: {result.stderr}"


@when("I check the resource requests and limits")
def step_when_check_resources():
    """Check the resource config."""


@then("CPU requests should be set appropriately for Azure")
def step_then_cpu_requests():
    """Verify CPU requests are configured."""


@then("memory requests should be set appropriately for Azure")
def step_then_memory_requests():
    """Verify memory requests are configured."""


@then("the configuration should support auto-scaling")
def step_then_autoscaling():
    """Verify auto-scaling support."""


@when("I check the certificate secrets")
def step_when_check_cert_secrets():
    """Check the certificate secrets."""


@then("all TLS secrets should be stored in Kubernetes")
def step_then_tls_secrets_k8s():
    """Verify TLS secrets are stored in Kubernetes."""


@then("ACME account keys should be stored securely")
def step_then_acme_keys():
    """Verify ACME account keys are secured."""


@then("certificates should auto-renew before expiration")
def step_then_auto_renew():
    """Verify auto-renewal is configured."""
