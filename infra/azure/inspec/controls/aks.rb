# encoding: utf-8
# =============================================================================
# File: infra/azure/inspec/controls/aks.rb
# Purpose: InSpec tests for Azure AKS cluster validation
# Usage: inspec exec infra/azure/inspec/ -t azure://
# Dependencies: inspec-azure, inspec-k8s
# Owner: Fawkes Platform Team
# =============================================================================

title 'Azure AKS Cluster Validation Tests'

# Azure credentials from environment or CLI config
resource_group = attribute('resource_group', default: 'fawkes-rg', description: 'Azure resource group name')
cluster_name = attribute('cluster_name', default: 'fawkes-aks', description: 'AKS cluster name')

# Test AT-E1-001: AKS cluster exists and is running
control 'aks-cluster-exists' do
  impact 1.0
  title 'AKS cluster should exist and be running'
  desc 'Verify that the AKS cluster is provisioned and in running state'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.provisioningState') { should eq 'Succeeded' }
    its('properties.powerState.code') { should eq 'Running' }
  end
end

# Test: Node count meets minimum requirements
control 'aks-node-count' do
  impact 1.0
  title 'AKS cluster should have minimum required nodes'
  desc 'Verify that the cluster has at least 2 nodes running'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    # System pool should have at least 2 nodes
    its('properties.agentPoolProfiles') { should_not be_empty }
  end

  # Get agent pools and check count
  agent_pools = azure_aks_cluster(resource_group: resource_group, name: cluster_name).properties.agentPoolProfiles

  describe "Total node count across all pools" do
    it "should be at least 2" do
      total_count = agent_pools.inject(0) { |sum, pool| sum + pool['count'].to_i }
      expect(total_count).to be >= 2
    end
  end
end

# Test: System and user node pools are separated
control 'aks-node-pool-separation' do
  impact 0.8
  title 'System and user node pools should be separated'
  desc 'Verify that system and user workloads use separate node pools'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.agentPoolProfiles.count') { should be >= 2 }
  end

  agent_pools = azure_aks_cluster(resource_group: resource_group, name: cluster_name).properties.agentPoolProfiles

  describe "Node pool configuration" do
    it "should have a system node pool" do
      system_pools = agent_pools.select { |p| p['mode'] == 'System' }
      expect(system_pools).not_to be_empty
    end

    it "should have a user node pool" do
      user_pools = agent_pools.select { |p| p['mode'] == 'User' }
      expect(user_pools).not_to be_empty
    end
  end
end

# Test: Azure CNI networking is configured
control 'aks-azure-cni' do
  impact 1.0
  title 'Azure CNI networking should be configured'
  desc 'Verify that the cluster uses Azure CNI for networking'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.networkProfile.networkPlugin') { should eq 'azure' }
  end
end

# Test: Managed identity is enabled
control 'aks-managed-identity' do
  impact 1.0
  title 'Managed identity should be enabled'
  desc 'Verify that the cluster uses managed identity instead of service principal'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('identity.type') { should match /SystemAssigned/i }
  end
end

# Test: Network policy is enabled
control 'aks-network-policy' do
  impact 0.7
  title 'Network policy should be enabled'
  desc 'Verify that network policy is configured (azure or calico)'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.networkProfile.networkPolicy') { should_not be_nil }
    its('properties.networkProfile.networkPolicy') { should match /azure|calico/i }
  end
end

# Test: RBAC is enabled
control 'aks-rbac-enabled' do
  impact 1.0
  title 'Kubernetes RBAC should be enabled'
  desc 'Verify that role-based access control is enabled'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.enableRBAC') { should eq true }
  end
end

# Test: Azure RBAC integration
control 'aks-azure-rbac' do
  impact 0.8
  title 'Azure RBAC for Kubernetes should be enabled'
  desc 'Verify that Azure RBAC is configured for Kubernetes authorization'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    # Check if aadProfile exists and has enableAzureRBAC set
    its('properties.aadProfile.enableAzureRBAC') { should eq true }
  end
end

# Test: Auto-scaling is configured on user pool
control 'aks-autoscaling-enabled' do
  impact 0.7
  title 'Auto-scaling should be enabled on user node pool'
  desc 'Verify that user node pool has auto-scaling configured'

  agent_pools = azure_aks_cluster(resource_group: resource_group, name: cluster_name).properties.agentPoolProfiles
  user_pools = agent_pools.select { |p| p['mode'] == 'User' }

  describe "User node pool auto-scaling" do
    it "should have at least one user pool with auto-scaling enabled" do
      autoscaling_pools = user_pools.select { |p| p['enableAutoScaling'] == true }
      expect(autoscaling_pools).not_to be_empty
    end
  end
end

# Test: Monitoring is enabled
control 'aks-monitoring-enabled' do
  impact 0.8
  title 'Azure Monitor should be enabled'
  desc 'Verify that Azure Monitor integration is configured'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.addonProfiles.omsagent.enabled') { should eq true }
  end
end

# Test: OIDC issuer is enabled (for workload identity)
control 'aks-oidc-issuer' do
  impact 0.6
  title 'OIDC issuer should be enabled'
  desc 'Verify that OIDC issuer is enabled for workload identity'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.oidcIssuerProfile.enabled') { should eq true }
  end
end

# Test: Appropriate VM sizes
control 'aks-vm-sizes' do
  impact 0.5
  title 'Node pools should use appropriate VM sizes'
  desc 'Verify that node pools use adequate VM sizes for platform workloads'

  agent_pools = azure_aks_cluster(resource_group: resource_group, name: cluster_name).properties.agentPoolProfiles

  describe "VM sizes" do
    it "should use at least D2s_v3 or equivalent" do
      agent_pools.each do |pool|
        vm_size = pool['vmSize']
        # Check that VM has at least 2 vCPUs (D2 or larger)
        expect(vm_size).to match(/D[2-9]|D[1-9][0-9]|E[2-9]|E[1-9][0-9]/)
      end
    end
  end
end

# Test: OS disk size is adequate
control 'aks-os-disk-size' do
  impact 0.5
  title 'OS disk size should be adequate'
  desc 'Verify that nodes have sufficient OS disk space'

  agent_pools = azure_aks_cluster(resource_group: resource_group, name: cluster_name).properties.agentPoolProfiles

  describe "OS disk sizes" do
    it "should be at least 100 GB" do
      agent_pools.each do |pool|
        disk_size = pool['osDiskSizeGB'] || 128 # Azure default is 128GB
        expect(disk_size).to be >= 100
      end
    end
  end
end

# Test: Load balancer SKU
control 'aks-load-balancer-sku' do
  impact 0.6
  title 'Load balancer should use Standard SKU'
  desc 'Verify that the cluster uses Standard load balancer for production features'

  describe azure_aks_cluster(resource_group: resource_group, name: cluster_name) do
    it { should exist }
    its('properties.networkProfile.loadBalancerSku') { should eq 'standard' }
  end
end

# Kubernetes-level tests (requires kubectl context)
# These tests run against the Kubernetes API

# Test: All nodes are Ready
control 'k8s-nodes-ready' do
  impact 1.0
  title 'All Kubernetes nodes should be Ready'
  desc 'Verify that all nodes in the cluster are in Ready state'
  tag 'kubernetes'

  only_if('Kubernetes context is configured') do
    command('kubectl cluster-info').exit_status == 0
  end

  describe command('kubectl get nodes -o json | jq -r \'.items[] | select(.status.conditions[] | select(.type=="Ready" and .status!="True")) | .metadata.name\'') do
    its('stdout') { should be_empty }
  end

  describe command('kubectl get nodes --no-headers | wc -l') do
    its('stdout.to_i') { should be >= 2 }
  end
end

# Test: System pods are running
control 'k8s-system-pods-running' do
  impact 1.0
  title 'System pods should be running'
  desc 'Verify that all kube-system pods are in Running state'
  tag 'kubernetes'

  only_if('Kubernetes context is configured') do
    command('kubectl cluster-info').exit_status == 0
  end

  describe command('kubectl get pods -n kube-system -o json | jq -r \'.items[] | select(.status.phase!="Running" and .status.phase!="Succeeded") | .metadata.name\'') do
    its('stdout') { should be_empty }
  end
end

# Test: CoreDNS is running
control 'k8s-coredns-running' do
  impact 1.0
  title 'CoreDNS should be running'
  desc 'Verify that DNS resolution is working in the cluster'
  tag 'kubernetes'

  only_if('Kubernetes context is configured') do
    command('kubectl cluster-info').exit_status == 0
  end

  describe command('kubectl get deployment -n kube-system coredns -o jsonpath="{.status.availableReplicas}"') do
    its('stdout.to_i') { should be >= 2 }
  end
end

# Test: Storage class exists
control 'k8s-storage-class' do
  impact 0.8
  title 'Default storage class should exist'
  desc 'Verify that a default storage class is configured'
  tag 'kubernetes'

  only_if('Kubernetes context is configured') do
    command('kubectl cluster-info').exit_status == 0
  end

  describe command('kubectl get storageclass -o json | jq -r \'.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true") | .metadata.name\'') do
    its('stdout') { should_not be_empty }
  end
end

# Test: Azure CNI pods are running
control 'k8s-azure-cni-running' do
  impact 0.8
  title 'Azure CNI components should be running'
  desc 'Verify that Azure CNI networking components are operational'
  tag 'kubernetes'

  only_if('Kubernetes context is configured') do
    command('kubectl cluster-info').exit_status == 0
  end

  describe command('kubectl get daemonset -n kube-system azure-cni-networkmonitor -o jsonpath="{.status.numberReady}"') do
    its('exit_status') { should eq 0 }
  end
end

# Test: Metrics server is available
control 'k8s-metrics-server' do
  impact 0.6
  title 'Metrics server should be available'
  desc 'Verify that metrics server is deployed for resource monitoring'
  tag 'kubernetes'

  only_if('Kubernetes context is configured') do
    command('kubectl cluster-info').exit_status == 0
  end

  describe command('kubectl get deployment -n kube-system metrics-server -o jsonpath="{.status.availableReplicas}"') do
    its('stdout.to_i') { should be >= 1 }
  end
end
