
describe command('kubectl') do
  it { should exist }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end

describe command('kubectl version') do
  its('stdout') { should include "1.22.4" }
end

describe command('helm') do
  it { should exist }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end

describe command('helm version') do
  its('stdout') { should include  "3.6.3" }
end