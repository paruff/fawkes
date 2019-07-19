describe package('git') do
    it { should be_installed }
    its('version') { should eq '2.18.0' }
  end