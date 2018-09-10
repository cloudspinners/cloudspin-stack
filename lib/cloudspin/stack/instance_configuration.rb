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

      def add_values(values)
        @instance_values.merge!(values['instance_values']) if values['instance_values']
        @parameter_values.merge!(values['parameter_values']) if values['parameter_values']
        @resource_values.merge!(values['resource_values']) if values['resource_values']
        self
      end

      def instance_identifier
        if instance_values['identifier']
          instance_values['identifier']
        else
          stack_name
        end
      end

    end

    class NoInstanceIdentifierError < StandardError; end

  end
end

