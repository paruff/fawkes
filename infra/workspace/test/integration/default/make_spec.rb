  describe command('make') do
    it { should exist }
  end

  describe command('make -v') do
    its('stdout') { should include "3.81" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
