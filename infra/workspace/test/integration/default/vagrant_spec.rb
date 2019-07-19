describe package('vagrant') do
    it { should be_installed }
    its('version') { should eq '2.2.5' }
  end