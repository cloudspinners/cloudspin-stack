require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class InstanceConfiguration

      attr_reader :stack_definition
      attr_reader :stack_name
      attr_reader :base_folder

      attr_reader :instance_values
      attr_reader :parameter_values
      attr_reader :resource_values

      attr_reader :terraform_backend

      def initialize(stack_definition, base_folder = '.')
        @stack_definition = stack_definition
        @stack_name = stack_definition.name
        @base_folder = base_folder
        @instance_values = {}
        @parameter_values = {}
        @resource_values = {}
        @terraform_backend = {}
        @state_folder = nil
      end

      def self.from_files(
          *configuration_files,
          stack_definition:,
          base_folder: '.'
      )
        config = self.new(stack_definition, base_folder)
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
        add_terraform_backend(values['terraform_backend'])
        self
      end

      def add_terraform_backend(values_to_add)
        @terraform_backend.merge!(values_to_add) if values_to_add
        if @terraform_backend.empty?
          @terraform_backend['statefile_folder'] = default_state_folder
        else
          @terraform_backend['key'] = default_state_key
        end
      end

      def has_local_state_configuration?
        ! @terraform_backend['statefile_folder'].nil?
      end

      def local_statefile
        "#{@terraform_backend['statefile_folder']}/#{instance_identifier}.tfstate"
      end

      def has_remote_state_configuration?
        ! @terraform_backend['key'].nil?
      end

      def default_state_folder
        Pathname.new("#{base_folder}/state/#{instance_identifier}").realdirpath.to_s
      end

      def default_state_key
        "/#{instance_identifier}.tfstate"
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
          'resources' => resource_values,
          'terraform_backend' => terraform_backend
        }.to_s
      end

    end

  end
end

