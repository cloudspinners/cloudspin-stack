require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class InstanceConfiguration

      attr_reader :stack_definition
      attr_reader :base_folder

      attr_reader :instance_values
      attr_reader :parameter_values
      attr_reader :resource_values
      attr_reader :stack_values

      attr_reader :stack_name
      attr_reader :instance_identifier
      attr_reader :backend_configuration

      def initialize(
          configuration_values: {},
          stack_definition:,
          base_folder: '.'
      )
        # puts "DEBUG: InstanceConfiguration configuration_values: #{configuration_values}"
        @stack_definition = stack_definition
        @base_folder = base_folder

        @stack_values = configuration_values['stack'] || {}
        @instance_values = configuration_values['instance'] || {}
        @parameter_values = configuration_values['parameters'] || {}
        @resource_values = configuration_values['resources'] || {}
        @stack_name = @stack_values['name'] || stack_definition.name
        init_instance_identifier
        @backend_configuration = BackendConfiguration.new(
          terraform_backend_configuration_values: configuration_values['terraform_backend'] || {},
          instance_identifier: instance_identifier,
          stack_name: stack_name,
          base_folder: base_folder
        )
      end

      def init_instance_identifier
        @instance_identifier = if @instance_values['identifier']
          @instance_values['identifier']
        elsif @instance_values['group']
          @stack_name + '-' + @instance_values['group']
        else
          @stack_name
        end
      end

      def self.from_files(
          *configuration_files,
          stack_definition:,
          base_folder: '.'
      )
        configuration_values = load_configuration_values(configuration_files)
        self.new(
          stack_definition: stack_definition,
          base_folder: base_folder,
          configuration_values: configuration_values
        )
      end

      def self.load_configuration_values(configuration_files)
        configuration_values = {}
        configuration_files.flatten.each { |config_file|
          # puts "DEBUG: Reading configuration file: #{config_file}"
          configuration_values = configuration_values.deep_merge(yaml_file_to_hash(config_file))
        }
        configuration_values
      end

      def self.yaml_file_to_hash(yaml_file)
        if File.exists?(yaml_file)
          YAML.load_file(yaml_file) || {}
        else
          puts "WARNING: No configuration file: #{yaml_file}"
          {}
        end
      end

      def has_local_state_configuration?
        ! @backend_configuration.remote_state?
      end

      def has_remote_state_configuration?
        @backend_configuration.remote_state?
      end

      def to_s
        {
          'instance_identifier' => instance_identifier,
          'instance' => instance_values,
          'parameters' => parameter_values,
          'resources' => resource_values,
          'backend_configuration' => backend_configuration
        }.to_s
      end

    end

  end
end

# hat tip: https://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(second.to_h, &merger)
  end
end
