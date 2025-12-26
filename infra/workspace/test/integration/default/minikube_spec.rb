describe.one do
  describe file('/usr/local/bin/minikube') do
    it { should exist }
    it { should be_executable }
  end
  describe file('/usr/bin/minikube') do
    it { should exist }
    it { should be_executable }
  end
end

describe command('minikube version') do
  its('stdout') { should match(/minikube version: v?1\.24\.0/) }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end

# Validate namespaces
namespaces = ['default', 'kube-system', 'kube-public']
namespaces.each do |namespace|
  describe command("kubectl get namespace #{namespace}") do
    its('stdout') { should match(/#{namespace}/) }
    its('exit_status') { should eq 0 }
  end
end

# Validate Minikube cluster status
describe command('minikube status') do
  its('stdout') { should match(/host: Running/) }
  its('stdout') { should match(/kubelet: Running/) }
  its('stdout') { should match(/apiserver: Running/) }
  its('stdout') { should match(/kubeconfig: Configured/) }
  its('exit_status') { should eq 0 }
end
