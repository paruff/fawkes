  describe docker.version do
    its('Client.Version') { should cmp >= '18.09.6'}
  end

  # describe package('docker-compose') do
  #   it { should be_installed }
  #   its('version') { should eq '1.24.0' }
  # end

  # describe package('docker-machine') do
  #   it { should be_installed }
  #   its('version') { should eq '0.16.1' }
  # end