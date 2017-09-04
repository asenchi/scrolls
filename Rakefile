#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rake/testtask"

ENV['TESTOPTS'] = "-v"

Rake::TestTask.new do |t|
  t.test_files = FileList["test/**/test_*.rb"]
  t.verbose = true
end

task :default => :test
