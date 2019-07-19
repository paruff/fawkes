describe package('aws') do
    it { should be_installed }
    its('version') { should eq '1.16.200' }
  end