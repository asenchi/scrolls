#!/usr/bin/env rake
require "bundler/gem_tasks"

ENV['TESTOPTS'] = "-v"

require "rake/testtask"
Rake::TestTask.new do |t|
  t.pattern = "test/test_*.rb"
end

task :default => :test
