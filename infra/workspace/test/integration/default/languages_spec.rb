describe file('C:\\Program Files\\Java\\jdk1.8.0_211\\bin\\java.exe') do
    it { should exist }
   end
describe command('C:\\Program Files\\Java\\jdk1.8.0_211\\bin\\java.exe') do
    its(:exit_status) { should eq 0 }
  end

describe file('C:\\Program Files\\nodejs\\node.exe') do
    it { should exist }
   end
describe command('C:\\Program Files\\nodejs\\node.exe') do
    its(:exit_status) { should eq 0 }
  end