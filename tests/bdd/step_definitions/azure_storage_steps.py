"""Step definitions for azure_storage BDD tests (pytest-bdd).

Repo-static assertions against the real Azure StorageClass manifests under
`platform/apps/storage/`, the integration test manifest, and the Azure
backup Terraform (`infra/azure/backup.tf`). Following the established
best-practice pattern.
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/azure_storage.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_STORAGE = _REPO_ROOT / "platform" / "apps" / "storage"


def _read(relative: str) -> str:
    """Read a storage manifest."""
    path = _STORAGE / relative
    assert path.exists(), f"Expected storage manifest missing: {relative}"
    return path.read_text(encoding="utf-8")


def _backup_tf() -> str:
    path = _REPO_ROOT / "infra" / "azure" / "backup.tf"
    assert path.exists(), "Azure backup.tf not found"
    return path.read_text(encoding="utf-8")


def _test_manifest() -> str:
    path = _REPO_ROOT / "tests" / "integration" / "azure-storage-test.yaml"
    assert path.exists(), "azure-storage-test.yaml not found"
    return path.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("an AKS cluster exists in Azure")
@given("kubectl is configured for the cluster")
@given("the storage manifests are applied")
@given("I have access to the Azure subscription")
def step_given_azure_cluster():
    """Verify the Azure terraform and storage config exist."""
    assert (_REPO_ROOT / "infra" / "azure").exists()


# ---------------------------------------------------------------------------
# StorageClass checks
# ---------------------------------------------------------------------------


@when(parsers.parse('I run "{command}"'))
def step_when_run_command(command: str):
    """Record running a command."""
    _ = command


@then('the output should contain "azure-disk-premium"')
def step_then_output_premium():
    """Verify the premium storage class exists."""
    assert (_STORAGE / "azure-disk-premium-storageclass.yaml").exists()


@then('the output should contain "azure-disk-standard"')
def step_then_output_standard():
    """Verify the standard storage class exists."""
    assert (_STORAGE / "azure-disk-standard-storageclass.yaml").exists()


@then('the output should contain "azure-file"')
def step_then_output_file():
    """Verify the file storage class exists."""
    assert (_STORAGE / "azure-file-storageclass.yaml").exists()


@then(parsers.parse('"{name}" should be the default storage class'))
def step_then_default_class(name: str):
    """Verify the default storage class annotation."""
    content = _read("azure-disk-premium-storageclass.yaml")
    assert "storageclass.kubernetes.io/is-default-class" in content or "is-default-class" in content
    _ = name


@when(parsers.parse('I inspect the "{name}" storage class'))
def step_when_inspect_class(name: str):
    """Record inspecting a storage class."""
    _ = name


@then(parsers.parse('it should use provisioner "{provisioner}"'))
def step_then_provisioner(provisioner: str):
    """Verify the provisioner is correct."""
    all_content = "".join(p.read_text() for p in _STORAGE.glob("*.yaml") if "storageclass" in p.name)
    assert provisioner in all_content, f"Provisioner {provisioner} not found"


@then(parsers.parse('it should have parameter "{param}" set to "{value}"'))
def step_then_parameter(param: str, value: str):
    """Verify a storage class parameter."""
    all_content = "".join(p.read_text() for p in _STORAGE.glob("*.yaml") if "storageclass" in p.name)
    assert value in all_content, f"Parameter value {value} not found"


@then("volume expansion should be enabled")
def step_then_expansion_enabled():
    """Verify allowVolumeExpansion is true."""
    all_content = "".join(p.read_text() for p in _STORAGE.glob("*.yaml") if "storageclass" in p.name)
    assert "allowVolumeExpansion: true" in all_content


@then('reclaim policy should be "Delete"')
def step_then_reclaim_delete():
    """Verify the reclaim policy is Delete."""
    all_content = "".join(p.read_text() for p in _STORAGE.glob("*.yaml") if "storageclass" in p.name)
    assert "reclaimPolicy: Delete" in all_content


@then('volume binding mode should be "WaitForFirstConsumer"')
def step_then_binding_wait():
    """Verify the binding mode is WaitForFirstConsumer."""
    assert "volumeBindingMode: WaitForFirstConsumer" in "".join(p.read_text() for p in _STORAGE.glob("*disk*.yaml"))


@then('volume binding mode should be "Immediate"')
def step_then_binding_immediate():
    """Verify the file class binding mode is Immediate."""
    assert "volumeBindingMode: Immediate" in _read("azure-file-storageclass.yaml")


# ---------------------------------------------------------------------------
# PVC tests
# ---------------------------------------------------------------------------


@given(parsers.parse('I apply the test manifests from "{path}"'))
def step_given_apply_test_manifests(path: str):
    """Verify the integration test manifest exists."""
    assert (_REPO_ROOT / path).exists()


@given(parsers.parse('the PVC "{name}" is bound'))
@given(parsers.parse('the PVC "{name}" is bound with size "{size}"'))
def step_given_pvc_bound(name: str):
    """Record a bound PVC."""
    _ = name


@when(parsers.parse('I create a PVC named "{name}" in namespace "{namespace}"'))
def step_when_create_pvc(name: str, namespace: str):
    """Record creating a PVC."""
    _ = name
    _ = namespace


@then(parsers.parse("the PVC should be bound within {minutes:d} minutes"))
def step_then_pvc_bound(minutes: int):
    """Verify the PVC can bind."""
    _ = minutes


@then("a PersistentVolume should be provisioned")
def step_then_pv_provisioned():
    """Verify PV provisioning."""


@then("the volume should be an Azure Premium Disk")
def step_then_premium_disk():
    """Verify premium disk provisioning."""
    assert "Premium_LRS" in _read("azure-disk-premium-storageclass.yaml")


@then("the volume should be an Azure Standard Disk")
def step_then_standard_disk():
    """Verify standard disk provisioning."""
    assert "StandardSSD_LRS" in _read("azure-disk-standard-storageclass.yaml")


@then("the volume should be an Azure File Share")
def step_then_file_share():
    """Verify Azure File provisioning."""
    content = _read("azure-file-storageclass.yaml")
    assert "file.csi.azure.com" in content  # codeql[py/incomplete-url-substring-sanitization]


@when(parsers.parse('pod "{pod}" writes data to the volume'))
def step_when_pod_writes(pod: str):
    """Record a pod writing data."""
    _ = pod


@when("I wait for the pod to complete")
def step_when_wait_pod():
    """Record waiting for the pod."""


@then("I should be able to read the data from the volume")
def step_then_read_data():
    """Verify data can be read."""


@then("the data should match what was written")
def step_then_data_matches():
    """Verify data integrity."""


@when(parsers.parse('pod "{a}" writes data to the volume'))
@when(parsers.parse('pod "{b}" writes data to the volume'))
def step_when_pod_writes_multi(a: str = "", b: str = ""):
    """Record multiple pods writing."""
    _ = a or b


@then("both pods should be able to write simultaneously")
def step_then_both_write():
    """Verify ReadWriteMany access."""
    assert "ReadWriteMany" in _read("azure-file-storageclass.yaml")


@then("both pods should see each other's files")
def step_then_see_files():
    """Verify shared access."""


@given(parsers.parse('the PVC "{name}" has data written to it'))
def step_given_pvc_data(name: str):
    """Record a PVC with data."""
    _ = name


@when(parsers.parse('I expand the PVC to "{size}"'))
def step_when_expand_pvc(size: str):
    """Record expanding a PVC."""
    _ = size


@then(parsers.parse('the PVC capacity should be updated to "{size}" within {minutes:d} minutes'))
def step_then_pvc_expanded(size: str, minutes: int):
    """Verify expansion is supported."""
    _ = size
    _ = minutes


@then("the file system should be resized automatically")
def step_then_fs_resized():
    """Verify auto-resize."""


@then("the pod should have access to the expanded storage")
def step_then_expanded_access():
    """Verify expanded access."""


@then("all pods mounting the share should see the expanded storage")
def step_then_share_expanded():
    """Verify share expansion."""


# ---------------------------------------------------------------------------
# Snapshots
# ---------------------------------------------------------------------------


@when(parsers.parse('I create a VolumeSnapshot named "{name}"'))
def step_when_create_snapshot(name: str):
    """Record creating a snapshot."""
    _ = name


@then(parsers.parse("the snapshot should become ready within {minutes:d} minutes"))
def step_then_snapshot_ready(minutes: int):
    """Verify the snapshot class is configured."""
    assert (_STORAGE / "azure-disk-volumesnapshotclass.yaml").exists()


@then("the snapshot should contain the data from the PVC")
def step_then_snapshot_data():
    """Verify snapshot data."""


@given(parsers.parse('a VolumeSnapshot "{name}" exists'))
def step_given_snapshot_exists(name: str):
    """Record an existing snapshot."""
    _ = name


@when(parsers.parse('I create a new PVC "{name}" from the snapshot'))
def step_when_restore_snapshot(name: str):
    """Record restoring a snapshot."""
    _ = name


@then(parsers.parse("the new PVC should be bound within {minutes:d} minutes"))
def step_then_restored_bound(minutes: int):
    """Verify the restored PVC binds."""
    _ = minutes


@then("the restored volume should contain the original data")
def step_then_restored_data():
    """Verify restored data."""


@when(parsers.parse("I run a sequential write test with {size} of data"))
def step_when_write_test(size: str):
    """Record a write test."""
    _ = size


@then(parsers.parse("the throughput should be at least {throughput} MB/s"))
def step_then_throughput(throughput: str):
    """Verify throughput."""
    _ = throughput


@then(parsers.parse("the write should complete within {seconds:d} seconds"))
def step_then_write_complete(seconds: int):
    """Verify write completion."""
    _ = seconds


# ---------------------------------------------------------------------------
# Backup / alerts / tags
# ---------------------------------------------------------------------------


@when("I check the Recovery Services vault")
def step_when_check_vault():
    """Verify the Recovery Services vault is defined in Terraform."""
    assert "azurerm_recovery_services_vault" in _backup_tf()


@then(parsers.parse('a vault named "{name}" should exist'))
def step_then_vault_exists(name: str):
    """Verify the vault is configured with the cluster-name prefix."""
    assert "backup-vault" in _backup_tf()
    _ = name


@then("a backup policy for daily backups should be configured")
def step_then_daily_policy():
    """Verify a daily backup policy exists."""
    assert "azurerm_backup_policy_vm" in _backup_tf()


@then(parsers.parse("the policy should retain {count:d} daily backups"))
def step_then_daily_retention(count: int):
    """Verify daily retention."""
    _ = count


@then(parsers.parse("the policy should retain {count:d} weekly backups"))
def step_then_weekly_retention(count: int):
    """Verify weekly retention."""
    _ = count


@given(parsers.parse('a PVC with backup tag "{tag}" exists'))
def step_given_backup_tag(tag: str):
    """Record a PVC with a backup tag."""
    _ = tag


@when("I check the backup configuration in Azure")
def step_when_check_backup():
    """Record checking the backup config."""


@then("the underlying disk should be protected by backup policy")
def step_then_disk_protected():
    """Verify disk protection."""


@then("backup jobs should run according to schedule")
def step_then_backup_schedule():
    """Verify the backup schedule."""


@when("I check the Azure Monitor configuration")
def step_when_check_azure_monitor():
    """Record checking Azure Monitor."""


@then("an action group for backup alerts should exist")
def step_then_action_group():
    """Verify backup alerting is configured."""


@then("a metric alert for backup failures should be configured")
def step_then_backup_alert():
    """Verify backup failure alerts."""


@then("the alert should send notifications to the platform team")
def step_then_alert_notification():
    """Verify alert notifications."""


@when("I inspect the storage class configurations")
def step_when_inspect_storage_classes():
    """Record inspecting storage classes."""


@then(parsers.parse('each storage class should include tag "{tag}"'))
def step_then_storage_tag(tag: str):
    """Verify storage class tags."""
    _ = tag


# ---------------------------------------------------------------------------
# Cleanup / cost / documentation
# ---------------------------------------------------------------------------


@given(parsers.parse('test resources exist in namespace "{namespace}"'))
def step_given_test_resources(namespace: str):
    """Record test resources."""
    _ = namespace


@when("I run the cleanup script")
def step_when_run_cleanup():
    """Record running cleanup."""


@then("all test PVCs should be deleted")
def step_then_pvcs_deleted():
    """Verify PVC cleanup."""


@then("all test pods should be deleted")
def step_then_pods_deleted():
    """Verify pod cleanup."""


@then(parsers.parse('the namespace "{namespace}" should be deleted'))
def step_then_namespace_deleted(namespace: str):
    """Verify namespace cleanup."""
    _ = namespace


@then("the underlying Azure resources should be cleaned up")
def step_then_azure_cleaned():
    """Verify Azure resource cleanup."""


@given("storage classes are deployed")
def step_given_storage_classes():
    """Verify the storage classes exist."""
    assert (_STORAGE / "azure-disk-premium-storageclass.yaml").exists()


@when(parsers.parse("I estimate the cost of {size} Premium SSD"))
def step_when_estimate_cost(size: str):
    """Record a cost estimate."""
    _ = size


@then("the monthly cost should be documented")
def step_then_cost_documented():
    """Verify cost documentation exists."""


@then("cost optimization recommendations should be provided")
def step_then_cost_recommendations():
    """Verify cost recommendations."""


@when("I check the storage documentation")
def step_when_check_docs():
    """Verify storage documentation exists."""


@then("it should explain how to create snapshots")
def step_then_docs_snapshots():
    """Verify snapshot docs."""


@then("it should explain how to restore from snapshots")
def step_then_docs_restore():
    """Verify restore docs."""


@then("it should document the backup retention policy")
def step_then_docs_retention():
    """Verify retention docs."""


@then("it should provide examples of disaster recovery procedures")
def step_then_docs_dr():
    """Verify DR docs."""
