
describe command('kubectl') do
  it { should exist }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end

describe command('kubectl version') do
  its('stdout') { should include "1.15.1" }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end

describe command('helm') do
  it { should exist }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end

describe command('helm version') do
  its('stdout') { should include  "2.14.2" }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end