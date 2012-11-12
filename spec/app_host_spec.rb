require 'fileutils'
require File.dirname(__FILE__) + '/../lib/app_hosts'

describe AppHosts do
  before(:each) do
    @manager = AppHosts::HostManager.new File.dirname(__FILE__) + '/fixtures/app_hosts.yml'
  end
  
  it 'should parse line' do
    line = ' 127.0.0.1 example.com www.example.com beta.example.com '
    @manager.send(:parse_line, line).should == ['127.0.0.1', {
      :host => 'example.com',
      :aliases => ['www.example.com', 'beta.example.com']
    }]
  end
  
  it 'should not parse comments' do
    line = ' # 127.0.0.1 example.com www.example.com beta.example.com '
    @manager.send(:parse_line, line).should be_nil
  end    
  
  it 'should save file lines' do
    @manager.parse File.dirname(__FILE__) + '/fixtures/hosts'
    lines = [
      {:text => "# first line comment"},
      {:text => ""},
      {:text => "127.0.0.1 www.example.com example.com", :ip => '127.0.0.1', :host => 'www.example.com', :aliases => ['example.com']},
      {:text => "127.0.0.2 hello-example.com", :ip => '127.0.0.2', :host => 'hello-example.com', :aliases => []},
      {:text => "# last line comment"}
    ]
    @manager.lines.should =~ lines
  end
  
  it 'should replace ip address to line' do
    line = '127.0.0.1 example.com www.example.com beta.example.com'
    new_ip = '127.0.0.2'
    new_line = "#{new_ip} example.com www.example.com beta.example.com"
    @manager.replace_ip_to_line(line, new_ip).should == new_line
  end
  
  it 'should replace ip for specified host' do
    tmp_path = File.dirname(__FILE__) + '/../tmp'
    FileUtils.mkdir_p(tmp_path)
    host = "www.example.com"
    new_ip = '1.1.1.1'
    original_file_path = File.dirname(__FILE__) + '/fixtures/hosts'
    output_file_path = File.join(tmp_path, 'new_hosts.txt')
    new_content = <<-FILE
# first line comment

#{new_ip} www.example.com example.com
127.0.0.2 hello-example.com
# last line comment
FILE
    @manager.parse original_file_path
    @manager.replace_ip host, new_ip, output_file_path
    File.open output_file_path, 'r' do |file|
      file.read.should == new_content
    end
    FileUtils.rm_rf(tmp_path)
  end
  
  it 'should parse config file' do
    config = {
      'hosts_file_path' => 'hello',
      'host' => 'www.example.com',
      'addresses' => {
        'development' => '127.0.0.1',
        'staging' => '127.0.0.2',
        'beta' => '127.0.0.3',
        'production' => '127.0.0.4'
      }
    }
    @manager.instance_variable_get('@config').should == config
  end
  
  it 'should find host ip by name' do
    {
      'development' => '127.0.0.1',
      'staging' => '127.0.0.2',
      'beta' => '127.0.0.3',
      'production' => '127.0.0.4'
    }.each do |name, ip|
      @manager.find_ip_by_name(name).should == ip
    end
  end
  
  it 'should not find undefined address' do
    @manager.find_ip_by_name('undefined-name').should be_nil
  end
  
  it 'should replace ip for specified named host' do
    tmp_path = File.dirname(__FILE__) + '/../tmp'
    FileUtils.mkdir_p(tmp_path)    
    original_file_path = File.dirname(__FILE__) + '/fixtures/hosts'
    output_file_path = File.join(tmp_path, 'new_hosts.txt')
    named_host = 'production'
    new_ip = @manager.instance_variable_get('@config')['addresses']['production']
    new_content = <<-FILE
# first line comment

#{new_ip} www.example.com example.com
127.0.0.2 hello-example.com
# last line comment
FILE
    @manager.parse original_file_path
    @manager.switch_ip_to named_host, output_file_path
    File.open output_file_path, 'r' do |file|
      file.read.should == new_content
    end
    FileUtils.rm_rf(tmp_path)
  end
  
  it 'should add ip and hosts if not already specified' do
    tmp_path = File.dirname(__FILE__) + '/../tmp'
    FileUtils.mkdir_p(tmp_path)    
    original_file_path = File.dirname(__FILE__) + '/fixtures/hosts'
    output_file_path = File.join(tmp_path, 'new_hosts.txt')
    named_host = 'production'
    
    config = @manager.instance_variable_get('@config')
    config['host'] = 'new-example.com'
    @manager.instance_variable_set('@config', config)
    
    new_ip = @manager.instance_variable_get('@config')['addresses']['production']
    new_content = <<-FILE
# first line comment

127.0.0.1 www.example.com example.com
127.0.0.2 hello-example.com
# last line comment
#{new_ip} new-example.com
FILE
    @manager.parse original_file_path
    @manager.switch_ip_to named_host, output_file_path
    File.open output_file_path, 'r' do |file|
      file.read.should == new_content
    end
    FileUtils.rm_rf(tmp_path)
  end
end