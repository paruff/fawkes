  describe docker.version do
    its('Client.Version') { should cmp >= '20.10.6'}
  end

  describe command('docker-compose') do
    it { should exist }
  end

  describe command('docker-compose version') do
    its('stdout') { should include "2.2.2" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('docker-machine') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('docker-machine version') do
    its('stdout') { should include  "0.16.2" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end