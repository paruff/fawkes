  describe command('chef') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('chef -v') do
    its('stdout') { should include  "21.11.679" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('inspec') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('inspec version') do
    its('stdout') { should include  "4.38.9" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('kitchen') do
    it { should exist }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end

  describe command('inspec version') do
    its('stdout') { should include  "3.1.1" }
    its('stderr') { should eq '' }
    its('exit_status') { should eq 0 }
  end