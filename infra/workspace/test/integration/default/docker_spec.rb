  describe docker.version do
    its('Client.Version') { should cmp >= '18.09.6'}
  end

  describe command('docker-compose') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('docker-compose version') do
    its('stdout') { should include "1.24.0" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('docker-machine') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('docker-machine version') do
    its('stdout') { should include  "0.16.1" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end