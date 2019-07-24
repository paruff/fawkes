
  describe command('minikube') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('minikube version') do
    its('stdout') { should include  "1.2.0" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end