#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'

Dir[File.dirname(__FILE__) + '/lib/**/*.rake'].each{ |file| load file }

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w[--color --format documentation]
  t.pattern = 'spec/*_spec.rb'
end

task :default => :spec