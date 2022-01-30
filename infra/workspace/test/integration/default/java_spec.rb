describe command('java') do
  it { should exist }
end

describe command('java --version') do
  its('stdout') { should include "17.0.1" }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end