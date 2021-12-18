  describe command('inspec') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('inspec version') do
    its('stdout') { should include  "4.38.9" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end