# Mock Functions for External Commands
# =============================================================================
# Provides mock implementations for external commands used by scripts
# =============================================================================

# Mock kubectl with configurable responses
setup_kubectl_mock() {
  export MOCK_KUBECTL_RESPONSES="${TEST_TEMP_DIR}/kubectl_responses.json"
  cat > "${MOCK_KUBECTL_RESPONSES}" <<'EOF'
{
  "cluster-info": {"exit_code": 0, "output": "Kubernetes control plane is running"},
  "get_nodes": {"exit_code": 0, "output": "{\"items\":[{\"status\":{\"conditions\":[{\"type\":\"Ready\",\"status\":\"True\"}]}}]}"},
  "get_storageclass": {"exit_code": 0, "output": "{\"items\":[{\"metadata\":{\"name\":\"default\",\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}]}"},
  "get_pods": {"exit_code": 0, "output": "{\"items\":[]}"}
}
EOF

  # Create kubectl stub
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  mkdir -p "${TEST_TEMP_DIR}/bin"
  
  cat > "${TEST_TEMP_DIR}/bin/kubectl" <<'KUBECTL_MOCK'
#!/usr/bin/env bash
# Log the command
echo "kubectl $*" >> "${TEST_TEMP_DIR}/kubectl.log"

# Return mock response based on command
case "$1" in
  "cluster-info")
    echo "Kubernetes control plane is running"
    exit 0
    ;;
  "get")
    case "$2" in
      "nodes")
        if [[ "$*" == *"-o json"* ]]; then
          echo '{"items":[{"status":{"conditions":[{"type":"Ready","status":"True"}]}}]}'
        else
          echo "NAME     STATUS   ROLES    AGE   VERSION"
          echo "node1    Ready    master   1d    v1.28.0"
        fi
        ;;
      "storageclass")
        if [[ "$*" == *"-o json"* ]]; then
          echo '{"items":[{"metadata":{"name":"default","annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}]}'
        else
          echo "NAME      PROVISIONER"
          echo "default   kubernetes.io/azure-disk"
        fi
        ;;
      "pods")
        if [[ "$*" == *"-o json"* ]]; then
          echo '{"items":[]}'
        else
          echo "No resources found"
        fi
        ;;
      "deployment")
        exit 0
        ;;
      *)
        echo '{"items":[]}'
        ;;
    esac
    ;;
  "wait")
    exit 0
    ;;
  "config")
    if [[ "$2" == "current-context" ]]; then
      echo "test-context"
    fi
    ;;
  *)
    exit 0
    ;;
esac
KUBECTL_MOCK

  chmod +x "${TEST_TEMP_DIR}/bin/kubectl"
}

# Mock az (Azure CLI)
setup_az_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/az" <<'AZ_MOCK'
#!/usr/bin/env bash
echo "az $*" >> "${TEST_TEMP_DIR}/az.log"

case "$1" in
  "aks")
    case "$2" in
      "get-credentials")
        echo "Merged \"test-cluster\" as current context"
        exit 0
        ;;
      "show")
        echo '{"name":"test-cluster","location":"eastus","provisioningState":"Succeeded"}'
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  "account")
    if [[ "$2" == "show" ]]; then
      echo '{"id":"test-subscription","name":"Test Subscription"}'
    fi
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
AZ_MOCK

  chmod +x "${TEST_TEMP_DIR}/bin/az"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Mock aws CLI
setup_aws_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/aws" <<'AWS_MOCK'
#!/usr/bin/env bash
echo "aws $*" >> "${TEST_TEMP_DIR}/aws.log"

case "$1" in
  "eks")
    case "$2" in
      "update-kubeconfig")
        echo "Updated context test-cluster"
        exit 0
        ;;
      "describe-cluster")
        echo '{"cluster":{"name":"test-cluster","status":"ACTIVE"}}'
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac
AWS_MOCK

  chmod +x "${TEST_TEMP_DIR}/bin/aws"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Mock gcloud CLI
setup_gcloud_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/gcloud" <<'GCLOUD_MOCK'
#!/usr/bin/env bash
echo "gcloud $*" >> "${TEST_TEMP_DIR}/gcloud.log"

case "$1" in
  "container")
    case "$2" in
      "clusters")
        if [[ "$3" == "get-credentials" ]]; then
          echo "Fetching cluster endpoint and auth data"
          exit 0
        fi
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac
GCLOUD_MOCK

  chmod +x "${TEST_TEMP_DIR}/bin/gcloud"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Mock terraform
setup_terraform_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/terraform" <<'TERRAFORM_MOCK'
#!/usr/bin/env bash
echo "terraform $*" >> "${TEST_TEMP_DIR}/terraform.log"

case "$1" in
  "init")
    echo "Terraform has been successfully initialized!"
    exit 0
    ;;
  "plan")
    echo "No changes. Infrastructure is up-to-date."
    exit 0
    ;;
  "apply")
    echo "Apply complete! Resources: 0 added, 0 changed, 0 destroyed."
    exit 0
    ;;
  "output")
    echo '{"value":"test-output"}'
    exit 0
    ;;
  *)
    exit 0
    ;;
esac
TERRAFORM_MOCK

  chmod +x "${TEST_TEMP_DIR}/bin/terraform"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Mock argocd CLI
setup_argocd_mock() {
  mkdir -p "${TEST_TEMP_DIR}/bin"
  cat > "${TEST_TEMP_DIR}/bin/argocd" <<'ARGOCD_MOCK'
#!/usr/bin/env bash
echo "argocd $*" >> "${TEST_TEMP_DIR}/argocd.log"

case "$1" in
  "login")
    echo "Logged in successfully"
    exit 0
    ;;
  "app")
    case "$2" in
      "get")
        echo "Name: test-app"
        echo "Status: Healthy"
        exit 0
        ;;
      "sync")
        echo "Synced successfully"
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac
ARGOCD_MOCK

  chmod +x "${TEST_TEMP_DIR}/bin/argocd"
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
}

# Setup all mocks
setup_all_mocks() {
  setup_kubectl_mock
  setup_az_mock
  setup_aws_mock
  setup_gcloud_mock
  setup_terraform_mock
  setup_argocd_mock
}

# Verify mock was called
assert_mock_called() {
  local mock_name="$1"
  local log_file="${TEST_TEMP_DIR}/${mock_name}.log"
  
  if [[ ! -f "${log_file}" ]]; then
    echo "Mock ${mock_name} was not called (log file not found)"
    return 1
  fi
  
  if [[ ! -s "${log_file}" ]]; then
    echo "Mock ${mock_name} was not called (log file empty)"
    return 1
  fi
  
  return 0
}

# Verify mock was called with specific arguments
assert_mock_called_with() {
  local mock_name="$1"
  local expected_args="$2"
  local log_file="${TEST_TEMP_DIR}/${mock_name}.log"
  
  if ! grep -q "${expected_args}" "${log_file}"; then
    echo "Mock ${mock_name} was not called with expected arguments: ${expected_args}"
    echo "Actual calls:"
    cat "${log_file}"
    return 1
  fi
  
  return 0
}
