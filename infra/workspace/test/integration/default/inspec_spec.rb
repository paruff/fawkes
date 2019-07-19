describe package('inspec') do
    it { should be_installed }
    its('version') { should eq '4.7.3.1' }
  end