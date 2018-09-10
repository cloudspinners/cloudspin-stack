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
        @instance_values.merge!(values['instance']) if values['instance']
        @parameter_values.merge!(values['parameters']) if values['parameters']
        @resource_values.merge!(values['resources']) if values['resources']
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

