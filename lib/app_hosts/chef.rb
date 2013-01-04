require 'chef/knife'
require 'chef/data_bag_item'
require 'chef/search/query'

module AppHosts::Chef
  # Set up chef configuration
  def self.configure_chef
    knife = Chef::Knife.new
    # If you don't do this it gets thrown into debug mode
    knife.config = { :verbosity => 1 }
    knife.configure_chef
  end

  # Do a search on the Chef server and return an attary of the requested
  # matching attributes
  def self.search_chef_nodes(query = '*:*', arg = :ipaddress, limit = 1000)
    search_proc = \
      case arg
      when Proc
        arg
      when Hash
        iface, family = arg.keys.first.to_s, arg.values.first.to_s
        Proc.new do |n|
          addresses = n["network"]["interfaces"][iface]["addresses"]
          addresses.select{|address, data| data["family"] == family }.to_a.first.first
        end
      when Symbol, String
        Proc.new{|n| n[arg.to_s]}
      else
        raise ArgumentError, 'Search arguments must be Proc, Hash, Symbol, String.'
      end
    Chef::Search::Query.new.search(:node, query, 'X_CHEF_id_CHEF_X asc', 0, limit)[0].map(&search_proc)
  end

  def self.get_data_bag_item(id, data_bag = :apps)
    Chef::DataBagItem.load(data_bag, id).raw_data
  end

  def self.get_encrypted_data_bag_item(id, data_bag = :apps, secret = nil)
    Chef::EncryptedDataBagItem.load(data_bag, id, secret).to_hash
  end

end
