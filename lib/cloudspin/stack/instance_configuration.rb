require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class InstanceConfiguration

      attr_reader :stack_definition
      attr_reader :stack_name

      attr_reader :instance_values
      attr_reader :parameter_values
      attr_reader :resource_values

      def initialize(stack_definition)
        @stack_definition = stack_definition
        @stack_name = stack_definition.name
        @instance_values = {}
        @parameter_values = {}
        @resource_values = {}
      end

      def self.from_files(stack_definition, *configuration_files)
        config = self.new(stack_definition)
        configuration_files.flatten.each { |config_file|
          config.add_values(load_file(config_file))
        }
        config
      end

      def self.load_file(yaml_file)
        if File.exists?(yaml_file)
          YAML.load_file(yaml_file) || {}
        else
          {}
        end
      end

      def add_values(values)
        @instance_values.merge!(values['instance']) if values['instance']
        @parameter_values.merge!(values['parameters']) if values['parameters']
        @resource_values.merge!(values['resources']) if values['resources']
        self
      end

      def instance_identifier
        if instance_values['identifier']
          instance_values['identifier']
        elsif instance_values['group']
          stack_name + '-' + instance_values['group']
        else
          stack_name
        end
      end

      def to_s
        {
          'instance' => instance_values,
          'parameters' => parameter_values,
          'resources' => resource_values
        }.to_s
      end

    end

  end
end

