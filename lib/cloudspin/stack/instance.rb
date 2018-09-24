require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class Instance

      include FileUtils

      attr_reader :id,
          :working_folder,
          :configuration

      def initialize(
            id:,
            stack_definition:,
            working_folder:,
            configuration:
      )
        validate_id(id)
        @id = id
        @stack_definition = stack_definition
        @working_folder   = working_folder
        @configuration    = configuration
      end

      def self.from_folder(
            *instance_configuration_files,
            definition_folder:,
            base_folder: '.',
            base_working_folder:
      )
        self.from_files(
            instance_configuration_files,
            stack_definition: Definition.from_folder(definition_folder),
            base_folder: base_folder,
            base_working_folder: base_working_folder
          )
      end

      def self.from_files(
            *instance_configuration_files,
            stack_definition:,
            base_folder: '.',
            base_working_folder:
      )
        instance_configuration = InstanceConfiguration.from_files(
          instance_configuration_files,
          stack_definition: stack_definition,
          base_folder: base_folder
        )
        self.new(
            id: instance_configuration.instance_identifier,
            stack_definition: stack_definition,
            working_folder: ensure_folder("#{base_working_folder}/#{instance_configuration.instance_identifier}"),
            configuration: instance_configuration
          )
      end

      def self.ensure_folder(folder)
        FileUtils.mkdir_p folder
        Pathname.new(folder).realdirpath.to_s
      end

      def validate_id(raw_id)
        raise "Stack instance ID '#{raw_id}' won't work. It needs to work as a filename." if /[^0-9A-Za-z.\-\_]/ =~ raw_id
        raise "Stack instance ID '#{raw_id}' won't work. No double dots allowed." if /\.\./ =~ raw_id
        raise "Stack instance ID '#{raw_id}' won't work. First character should be a letter." if /^[^A-Za-z]/ =~ raw_id
      end

      def parameter_values
        configuration.parameter_values
      end

      def resource_values
        configuration.resource_values
      end

      def plan(plan_destroy: false)
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.source_path, working_folder
        ensure_state_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: @backend_config)
          RubyTerraform.plan(terraform_command_parameters(destroy: plan_destroy))
        end
      end

      def plan_dry(plan_destroy: false)
        plan_command = RubyTerraform::Commands::Plan.new
        command_line_builder = plan_command.instantiate_builder
        configured_command = plan_command.configure_command(
            command_line_builder,
            terraform_command_parameters(:destroy => plan_destroy)
        )
        built_command = configured_command.build
        "cd #{working_folder} && #{built_command.to_s}"
      end

      def up
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.source_path, working_folder
        ensure_state_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: @backend_config)
          RubyTerraform.apply(terraform_command_parameters(auto_approve: true))
        end
      end

      def up_dry
        up_command = RubyTerraform::Commands::Apply.new
        command_line_builder = up_command.instantiate_builder
        configured_command = up_command.configure_command(command_line_builder, terraform_command_parameters)
        built_command = configured_command.build
        "cd #{working_folder} && #{built_command.to_s}"
      end

      def down
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.source_path, working_folder
        ensure_state_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: @backend_config)
          RubyTerraform.destroy(terraform_command_parameters(force: true))
        end
      end

      def down_dry
        down_command = RubyTerraform::Commands::Destroy.new
        command_line_builder = down_command.instantiate_builder
        configured_command = down_command.configure_command(command_line_builder, terraform_command_parameters)
        built_command = configured_command.build
        "cd #{working_folder} && #{built_command.to_s}"
      end

      def ensure_state_folder
        if configuration.has_local_state_configuration?
          Instance.ensure_folder(configuration.terraform_backend['statefile_folder'])
        end
      end

      def terraform_command_parameters(added_parameters = {})
        {
          vars: terraform_variables
        }.merge(terraform_state_configuration).merge(added_parameters)
      end

      def terraform_variables
        parameter_values.merge(resource_values) { |key, oldval, newval|
          raise "Duplicate values for terraform variable '#{key}' ('#{oldval}' and '#{newval}')"
        }.merge({ 'instance_identifier' => id })
      end

      def terraform_state_configuration
        if configuration.has_local_state_configuration?
          local_state_configuration
        elsif configuration.has_remote_state_configuration?
          # BUT, probably not here, not a -var
          remote_state_configuration
        else
          raise "InstanceConfiguration has neither local nor remote state configured"
        end
      end

      def local_state_configuration
        {
          state: configuration.local_statefile
        }
      end

      def remote_state_configuration
        {
          'backend-config' => "bucket=#{configuration.terraform_backend['bucket']}",
          'backend-config' => "region=#{configuration.terraform_backend['region']}",
          'backend-config' => "key=#{configuration.terraform_backend['key']}"
        }
      end

    end
  end
end
