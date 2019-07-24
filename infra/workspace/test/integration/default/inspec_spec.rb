  describe command('inspec') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('inspec version') do
    its('stdout') { should include  "4.7.3.1" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end