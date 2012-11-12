require File.dirname(__FILE__) + '/../app_hosts'

namespace :app_hosts do  
  desc 'Switch'
  task :switch, :named_host do |task, args|
    named_host = args[:named_host].to_s.strip
    raise "You must specify the named host: rake app_hosts:switch[NAMED_HOST]" if named_host.size == 0
    in_file = File.dirname(__FILE__) + '/../../spec/fixtures/hosts'
    out_file = 'test.txt'
    host = 'www.example.com'
    ip = '2.2.2.2'
    
    manager = AppHosts::HostManager.new 'config/app_hosts.yml'
    manager.parse
    manager.switch_ip_to named_host
  end
end