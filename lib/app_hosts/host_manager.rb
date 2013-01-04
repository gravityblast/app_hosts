require 'yaml'
require File.dirname(__FILE__) + '/chef.rb'

module AppHosts
  class HostManager

    attr_reader :hosts, :lines

    def initialize config_file_path
      @lines = []
      @parsed = false
      @config = YAML.load_file config_file_path
      parse_config_for_chef
    end

    def parse file_path=@config['hosts_file_path']
      @file_path = file_path
      parse_file file_path
      @parsed = true
    end

    def parse_config_for_chef
      configured_chef = false
      @config['addresses'].each do |key, value|
        next unless value['query']
        unless configured_chef
          Chef.configure_chef
          configured_chef = true
        end
        attr = eval value['attribute']
        @config['addresses'][key] = Chef.search_chef_nodes(value['query'], attr, 1).first
      end
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

      buffer = ''

      found = false
      @lines.each do |line|
        line = if line[:host] == host
          found = true
          build_line new_ip, line[:host], line[:aliases]
        else
          line[:text]
        end
        buffer << "#{line}\n"
      end

      buffer << "#{build_line(new_ip, host)}\n" if !found
      write_file buffer, file_path
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

    def write_file buffer, file_path
      buffer.gsub!(/"/, '\\"')
      buffer.gsub!(/'/){ |match| %|"'"\\'"'"|}
      cmd = "echo"
      if @config['use_sudo']
        system %|sudo sh -c '#{cmd} "#{buffer}\\c" > "#{file_path}"'|
      else
        system %|#{cmd} "#{buffer}\\c" > "#{file_path}"|
      end
    end
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
