describe command('java') do
  it { should exist }
end

describe command('java -version') do
  its('stdout') { should include "8.212.2" }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end