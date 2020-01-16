
  describe command('postman') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
  
  describe command('postman version') do
    its('stdout') { should include  "7.2.2" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end