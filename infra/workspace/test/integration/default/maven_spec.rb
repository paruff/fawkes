
  describe command('mvn') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('mvn version') do
    its('stdout') { should include  "0.16.1" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end