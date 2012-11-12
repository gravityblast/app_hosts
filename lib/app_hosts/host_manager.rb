require 'yaml'

module AppHosts
  class HostManager
    
    attr_reader :hosts, :lines
    
    def initialize config_file_path
      @lines = []
      @parsed = false
      @config = YAML.load_file config_file_path
    end
    
    def parse file_path=@config['hosts_file_path']
      @file_path = file_path
      parse_file file_path
      @parsed = true
    end
    
    def find_ip_by_name name
      pair = @config['addresses'].find{|key, value| key == name}
      pair ? pair.last : nil
    end
    
    def switch_ip_to named_host, file_path=@file_path
      new_ip = find_ip_by_name named_host
      raise "Named host not found: #{named_host}" unless new_ip
      replace_ip @config['host'], new_ip, file_path
    end
    
    def replace_ip host, new_ip, file_path=@file_path
      raise "You should parse original file before replacing ip address." unless @parsed
      File.open file_path, 'w' do |file|
        found = false
        @lines.each do |line|
          line = if line[:host] == host
            found = true
            build_line new_ip, line[:host], line[:aliases]
          else
            line[:text]
          end
          file.puts line
        end
        
        if !found
          file.puts build_line(new_ip, host)
        end
      end
    end        
    
    def build_line ip, host, aliases=[]
      "#{ip} #{host} #{aliases.join(' ')}".strip
    end
    
    def replace_ip_to_line line, new_ip
      new_line = ""
      line_attributes = parse_line line.strip.chomp
      if !line_attributes.nil?
        ip, attributes = line_attributes
        new_line << build_line(new_ip, attributes[:host], attributes[:aliases])
      end
      new_line
    end
    
  private
  
    def parse_file file_path
      each_file_line file_path do |line|        
        line_attributes = parse_line line
        if !line_attributes.nil?
          ip, attributes = line_attributes
          @lines << { :ip => ip, :host => attributes[:host], :aliases => attributes[:aliases], :text => line }
        else          
          @lines << { :text => line }
        end
      end
    end
    
    def each_file_line file_path
      File.open file_path, 'r' do |file|
        file.each do |line|
          yield line.chomp.strip
        end
      end
    end
    
    def parse_line line
      return nil if line.size == 0 || line =~ /^\s*#/
      attributes = line.split.collect &:strip
      [
        attributes.shift,
        :host => attributes.shift,
        :aliases => attributes
      ]
    end        
  end
end