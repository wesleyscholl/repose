# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc "Run console with repose loaded"
task :console do
  require "bundler/setup"
  require "repose"
  require "irb"
  
  ARGV.clear
  IRB.start
end

desc "Install gem locally"
task :install do
  sh "gem build repose.gemspec"
  sh "gem install repose-*.gem"
  sh "rm repose-*.gem"
end

desc "Release gem"
task :release do
  sh "gem build repose.gemspec"
  sh "gem push repose-*.gem"
  sh "rm repose-*.gem"
end