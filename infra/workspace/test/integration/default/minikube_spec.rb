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