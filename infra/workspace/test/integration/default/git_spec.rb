describe package('git') do
  it { should be_installed }
end

describe command('git --version') do
  its('stdout') { should match(/git version 2\.34\./) }
  its('exit_status') { should eq 0 }
end

describe.one do
  describe file('/usr/bin/git') do
    it { should exist }
    it { should be_executable }
  end
  describe file('/usr/local/bin/git') do
    it { should exist }
    it { should be_executable }
  end
end