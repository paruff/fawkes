
# describe command('C:\\Program Files\\nodejs\\node.exe') do
#     its(:exit_status) { should eq 0 }
#   end
describe package('node') do
    it { should be_installed }
    its('version') { should eq '10.16.0' }
  end