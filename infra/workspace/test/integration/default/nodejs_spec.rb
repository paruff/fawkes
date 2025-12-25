  describe command('node') do
    it { should exist }
    its('stderr') { should eq '' }
  end

  describe command('node --version') do
    its('stdout') { should include  "16.13.0" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
