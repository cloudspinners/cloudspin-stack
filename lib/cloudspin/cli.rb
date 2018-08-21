require 'thor'
require 'cloudspin/stack'

module Cloudspin
  class CLI < Thor

    class_option :file, :banner => 'YAML-CONFIG-FILE', :type => :array

    desc 'plan', 'Print the changes that will by applied when the \'stack up\' command is run'
    def plan
      puts "Get configuration from #{options[:file]}" if options[:file]
      stack = instance
      options[:file].each { |config_file|
        stack.add_config_from_yaml(config_file)
      }
      stack.plan
    end

    desc 'version', 'Print the version number'
    def version
      puts "cloudspin-stack: #{Cloudspin::Stack::VERSION}"
    end

    desc 'info', 'Print some info about arguments, for debugging'
    def info
      puts "Configuration file: #{options[:file]}"
    end

    no_commands do

      def instance
        Cloudspin::Stack::Instance.new(
          stack_definition: stack_definition,
          backend_config: {},
          working_folder: working_folder,
          statefile_folder: statefile_folder
        )
      end

      def stack_definition
        Cloudspin::Stack::Definition.from_file(terraform_source_folder + '/stack.yaml')
      end

      def stack_project_folder
        Pathname.new(Dir.pwd).realpath.to_s
      end

      def terraform_source_folder
        Pathname.new(stack_project_folder + '/src').realpath.to_s
      end

      def working_folder
        Pathname.new(stack_project_folder + '/work').realpath.to_s
      end

      def statefile_folder
        Pathname.new(stack_project_folder + '/state').realpath.to_s
      end

    end

    def self.exit_on_failure?
      true
    end

  end
end
