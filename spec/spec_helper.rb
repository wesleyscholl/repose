# frozen_string_literal: true

require "simplecov"
require "simplecov-lcov"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  
  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.single_report_path = "coverage/lcov.info"
  end
  
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
  
  minimum_coverage 80
end

require "bundler/setup"
require "ostruct"
require "repose"
require "webmock/rspec"
require "vcr"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure WebMock
  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)
  end
  
  # Clean up config file after tests
  config.after(:each) do
    config_file = File.expand_path("~/.repose_test.yml")
    File.delete(config_file) if File.exist?(config_file)
  end
end

# Configure VCR for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] }
  config.filter_sensitive_data('<OPENAI_API_KEY>') { ENV['OPENAI_API_KEY'] }
end