  describe command('vagrant') do
    it { should exist }
    its('stderr') { should eq '' }
  end

  describe command('vagrant version') do
    its('stdout') { should include  "2.2.19" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end