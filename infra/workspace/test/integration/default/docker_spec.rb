describe file('C:\\ProgramData\\chocolatey\\bin\\docker.exe') do
    it { should exist }
   end
# describe command('C:\\ProgramData\\chocolatey\\bin\\docker.exe') do
#     its(:exit_status) { should eq 0 }
#   end

describe file('C:\\ProgramData\\chocolatey\\bin\\docker-machine.exe') do
    it { should exist }
   end
describe command('C:\\ProgramData\\chocolatey\\bin\\docker-machine.exe') do
    its(:exit_status) { should eq 0 }
  end

  describe file('C:\\ProgramData\\chocolatey\\bin\\docker-compose.exe') do
    it { should exist }
   end
describe command('C:\\ProgramData\\chocolatey\\bin\\docker-compose.exe') do
    its(:exit_status) { should eq 0 }
  end