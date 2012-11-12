# -*- encoding: utf-8 -*-
require File.expand_path('../lib/app_hosts/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Andrea Franz"]
  gem.email         = ["andrea@gravityblast.com"]
  gem.description   = %q{Application based /etc/hosts manager}
  gem.summary       = %q{}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "app_hosts"
  gem.require_paths = ["lib"]
  gem.version       = AppHosts::VERSION
end
