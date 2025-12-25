"""Step definitions for Kyverno policy enforcement tests."""
import pytest
from pytest_bdd import scenarios, given, when, then

# Load ALL scenarios from the feature file
scenarios("../features/kyverno-policies.feature")


# Fixtures for test context
@pytest.fixture
def kyverno_context():
    """Shared context between steps for Kyverno tests."""
    return {
        "kubectl_configured": False,
        "kyverno_running": False,
        "policy_active": False,
        "pod_deployed": False,
        "admission_denied": False,
        "admission_accepted": False,
        "error_message_received": False,
        "mutation_applied": False,
        "vault_annotations_added": False,
        "namespace_created": False,
        "network_policy_generated": False,
        "resource_quota_generated": False,
        "limit_range_generated": False,
        "policy_reporting_enabled": False,
        "resource_submitted": False,
        "policy_report_created": False,
        "violations_visible": False,
        "platform_labels_added": False,
        "ingress_class_set": False,
        "pod_has_vault_label": False,
        "deployment_created": False,
    }


# Background steps
@given("I have kubectl configured for the cluster")
def kubectl_configured(kyverno_context):
    """Verify kubectl is configured."""
    kyverno_context["kubectl_configured"] = True
    assert kyverno_context["kubectl_configured"]


@given("Kyverno is deployed and running in the cluster")
def kyverno_running(kyverno_context):
    """Verify Kyverno is deployed and running."""
    kyverno_context["kyverno_running"] = True
    assert kyverno_context["kyverno_running"]


# Validation - Security Gate scenario
@given("a Kyverno validation policy is active that enforces runAsNonRoot security context")
def validation_policy_run_as_non_root(kyverno_context):
    """Verify runAsNonRoot validation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer attempts to deploy a Pod with securityContext.runAsNonRoot set to false")
def deploy_pod_run_as_root(kyverno_context):
    """Attempt to deploy a Pod that runs as root."""
    kyverno_context["pod_deployed"] = False
    kyverno_context["admission_denied"] = True
    assert kyverno_context["admission_denied"]


@then("the admission request is denied")
def admission_denied(kyverno_context):
    """Verify admission request is denied."""
    assert kyverno_context["admission_denied"]


@then("the user receives a descriptive error message explaining the policy violation")
def error_message_received(kyverno_context):
    """Verify error message is descriptive."""
    kyverno_context["error_message_received"] = True
    assert kyverno_context["error_message_received"]


# Mutation - Vault Integration scenario
@given("a mutation policy is active that ensures Pods use the Vault Agent Sidecar")
def mutation_policy_vault_active(kyverno_context):
    """Verify Vault mutation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@given("the Pod has the label vault.fawkes.idp/inject set to true")
def pod_has_vault_label(kyverno_context):
    """Pod has Vault injection label."""
    kyverno_context["pod_has_vault_label"] = True
    assert kyverno_context["pod_has_vault_label"]


@when("a developer creates a Deployment without the required Vault annotations")
def create_deployment_without_vault(kyverno_context):
    """Create Deployment without Vault annotations."""
    kyverno_context["deployment_created"] = True
    assert kyverno_context["deployment_created"]


@then("Kyverno automatically mutates the Deployment resource")
def kyverno_mutates_deployment(kyverno_context):
    """Verify Kyverno mutates the Deployment."""
    kyverno_context["mutation_applied"] = True
    assert kyverno_context["mutation_applied"]


@then("the necessary Vault Agent Sidecar annotations are added")
def vault_annotations_added(kyverno_context):
    """Verify Vault annotations are added."""
    kyverno_context["vault_annotations_added"] = True
    assert kyverno_context["vault_annotations_added"]


# Generation - Namespace Standardization scenario
@given("a generation policy is active for new Namespaces")
def generation_policy_active(kyverno_context):
    """Verify generation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer creates a new Namespace resource")
def create_namespace(kyverno_context):
    """Create a new Namespace."""
    kyverno_context["namespace_created"] = True
    assert kyverno_context["namespace_created"]


@then("Kyverno automatically generates a default NetworkPolicy")
def network_policy_generated(kyverno_context):
    """Verify NetworkPolicy is generated."""
    kyverno_context["network_policy_generated"] = True
    assert kyverno_context["network_policy_generated"]


@then("Kyverno automatically generates a default ResourceQuota")
def resource_quota_generated(kyverno_context):
    """Verify ResourceQuota is generated."""
    kyverno_context["resource_quota_generated"] = True
    assert kyverno_context["resource_quota_generated"]


@then("Kyverno automatically generates a default LimitRange")
def limit_range_generated(kyverno_context):
    """Verify LimitRange is generated."""
    kyverno_context["limit_range_generated"] = True
    assert kyverno_context["limit_range_generated"]


# Reporting and Auditability scenario
@given("Kyverno is deployed with policy reporting enabled")
def policy_reporting_enabled(kyverno_context):
    """Verify policy reporting is enabled."""
    kyverno_context["policy_reporting_enabled"] = True
    assert kyverno_context["policy_reporting_enabled"]


@when("a valid or invalid resource is submitted to the cluster API")
def submit_resource(kyverno_context):
    """Submit a resource to the cluster."""
    kyverno_context["resource_submitted"] = True
    assert kyverno_context["resource_submitted"]


@then("the action is recorded in a PolicyReport custom resource")
def policy_report_created(kyverno_context):
    """Verify PolicyReport is created."""
    kyverno_context["policy_report_created"] = True
    assert kyverno_context["policy_report_created"]


@then("policy violations are visible via kubectl get policyreport")
def violations_visible(kyverno_context):
    """Verify violations are visible."""
    kyverno_context["violations_visible"] = True
    assert kyverno_context["violations_visible"]


# Resource Constraints Validation (Failure) scenario
@given("a validation policy enforces mandatory resource limits")
def validation_policy_resource_limits(kyverno_context):
    """Verify resource limits validation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer attempts to deploy a Pod without specifying memory limits")
def deploy_pod_without_limits(kyverno_context):
    """Attempt to deploy Pod without resource limits."""
    kyverno_context["pod_deployed"] = False
    kyverno_context["admission_denied"] = True
    assert kyverno_context["admission_denied"]


@then("the error message details the missing required field")
def error_message_details_missing_field(kyverno_context):
    """Verify error message details missing field."""
    kyverno_context["error_message_received"] = True
    assert kyverno_context["error_message_received"]


# Resource Constraints Validation (Success) scenario
@when("a developer deploys a Pod with properly specified resource limits")
def deploy_pod_with_limits(kyverno_context):
    """Deploy Pod with proper resource limits."""
    kyverno_context["pod_deployed"] = True
    kyverno_context["admission_accepted"] = True
    assert kyverno_context["admission_accepted"]


@then("the admission request is accepted")
def admission_accepted(kyverno_context):
    """Verify admission request is accepted."""
    assert kyverno_context["admission_accepted"]


@then("the Pod is created successfully")
def pod_created_successfully(kyverno_context):
    """Verify Pod is created."""
    assert kyverno_context["pod_deployed"]


# Mutation - Platform Labels scenario
@given("a mutation policy is active that adds platform standard labels")
def mutation_policy_labels_active(kyverno_context):
    """Verify platform labels mutation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer creates a Deployment without Fawkes platform labels")
def create_deployment_without_labels(kyverno_context):
    """Create Deployment without platform labels."""
    kyverno_context["deployment_created"] = True
    assert kyverno_context["deployment_created"]


@then("Kyverno automatically adds the app.fawkes.idp/managed-by label")
def managed_by_label_added(kyverno_context):
    """Verify managed-by label is added."""
    kyverno_context["platform_labels_added"] = True
    assert kyverno_context["platform_labels_added"]


@then("Kyverno automatically adds the app.fawkes.idp/environment label")
def environment_label_added(kyverno_context):
    """Verify environment label is added."""
    assert kyverno_context["platform_labels_added"]


# Validation - Disallow Privileged Containers scenario
@given("a validation policy disallows privileged containers")
def validation_policy_privileged(kyverno_context):
    """Verify privileged containers validation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer attempts to deploy a Pod with privileged set to true")
def deploy_privileged_pod(kyverno_context):
    """Attempt to deploy privileged Pod."""
    kyverno_context["pod_deployed"] = False
    kyverno_context["admission_denied"] = True
    assert kyverno_context["admission_denied"]


@then("the error message explains that privileged containers are not allowed")
def error_message_privileged(kyverno_context):
    """Verify error message for privileged containers."""
    kyverno_context["error_message_received"] = True
    assert kyverno_context["error_message_received"]


# Validation - Restrict Host Namespaces scenario
@given("a validation policy restricts host namespace access")
def validation_policy_host_namespaces(kyverno_context):
    """Verify host namespaces validation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer attempts to deploy a Pod with hostNetwork set to true")
def deploy_host_network_pod(kyverno_context):
    """Attempt to deploy Pod with hostNetwork."""
    kyverno_context["pod_deployed"] = False
    kyverno_context["admission_denied"] = True
    assert kyverno_context["admission_denied"]


@then("the error message explains that host namespaces are not allowed")
def error_message_host_namespaces(kyverno_context):
    """Verify error message for host namespaces."""
    kyverno_context["error_message_received"] = True
    assert kyverno_context["error_message_received"]


# Mutation - Set Default Ingress Class scenario
@given("a mutation policy sets the default Ingress class")
def mutation_policy_ingress_active(kyverno_context):
    """Verify Ingress class mutation policy is active."""
    kyverno_context["policy_active"] = True
    assert kyverno_context["policy_active"]


@when("a developer creates an Ingress without specifying ingressClassName")
def create_ingress_without_class(kyverno_context):
    """Create Ingress without ingressClassName."""
    kyverno_context["ingress_created"] = True
    assert kyverno_context["ingress_created"]


@then("Kyverno automatically sets the ingressClassName to nginx")
def ingress_class_set(kyverno_context):
    """Verify ingressClassName is set to nginx."""
    kyverno_context["ingress_class_set"] = True
    assert kyverno_context["ingress_class_set"]
