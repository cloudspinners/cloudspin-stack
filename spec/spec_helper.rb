require 'bundler/setup'
require 'cloudspin/stack'
require 'tempfile'
require 'fileutils'
require 'definition_helpers'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include DefinitionHelpers
  config.include FileUtils
end
