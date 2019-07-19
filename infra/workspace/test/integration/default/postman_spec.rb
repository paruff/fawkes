describe package('postman') do
    it { should be_installed }
    its('version') { should eq '7.2.2' }
  end