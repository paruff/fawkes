describe package('java') do
  it { should be_installed }
  its('version') { should eq '8.212.2' }
end