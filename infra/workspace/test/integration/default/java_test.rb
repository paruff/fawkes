describe package('java') do
  it { should be_installed }
  its('version') { should eq '8.0.1910.12' }
end