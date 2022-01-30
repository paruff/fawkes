describe package('git') do
    it { should be_installed }
    its('version') { should include '2.34.' }
  end