  describe command('make') do
    it { should exist }
  end

  describe command('make -v') do
    its('stdout') { should include "4.3" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end
