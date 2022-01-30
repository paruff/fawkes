  describe command('aws') do
    it { should exist }
  end

  describe command('aws --version') do
    its('stdout') { should include  "2.4.6" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end