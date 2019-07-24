  describe command('aws') do
    it { should exist }
  end

  describe command('aws --version') do
    its('stdout') { should include  "1.16.200" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end