describe package('git') do
    it { should be_installed }
    its('version') { should include '2.20.0' }
  end