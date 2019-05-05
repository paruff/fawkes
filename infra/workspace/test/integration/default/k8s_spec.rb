describe file('C:\\ProgramData\\chocolatey\\bin\\kubectl.exe') do
    it { should exist }
   end
describe command('C:\\ProgramData\\chocolatey\\bin\\kubectl.exe') do
    its(:exit_status) { should eq 0 }
  end

describe file('C:\\ProgramData\\chocolatey\\bin\\helm.exe') do
    it { should exist }
   end
describe command('C:\\ProgramData\\chocolatey\\bin\\helm.exe') do
    its(:exit_status) { should eq 0 }
  end

  describe file('C:\\ProgramData\\chocolatey\\bin\\minikube.exe') do
    it { should exist }
   end
describe command('C:\\ProgramData\\chocolatey\\bin\\minikube.exe') do
    its(:exit_status) { should eq 0 }
  end