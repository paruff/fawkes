describe file('/usr/bin/aws').exist? || file('/usr/local/bin/aws').exist? do
  it { should eq true }
end

describe command('aws --version') do
  its('stdout') { should match(/aws-cli\/2\.4\.6/) }
  its('stderr') { should eq '' }
  its('exit_status') { should eq 0 }
end
