
  describe command('mvn') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 1 }
  end

  describe command('mvn -v') do
    its('stdout') { should include  "3.8.4" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
