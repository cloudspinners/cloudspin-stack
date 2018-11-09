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
            definition_location:,
            base_folder: '.',
            base_working_folder:
      )
        self.from_files(
            instance_configuration_files,
            stack_definition: Definition.from_location(
                definition_location,
                definition_cache_folder: "#{base_folder}/.cloudspin/definitions"
            ),
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

        if instance_configuration.has_remote_state_configuration? && stack_definition.is_from_remote?
          add_terraform_backend_source(stack_definition.source_path)
        end

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

      def self.add_terraform_backend_source(terraform_source_folder)
        puts "DEBUG: Creating file #{terraform_source_folder}/_cloudspin_created_backend.tf"
        File.open("#{terraform_source_folder}/_cloudspin_created_backend.tf", 'w') { |backend_file|
          backend_file.write(<<~TF_BACKEND_SOURCE
            terraform {
              backend "s3" {}
            }
          TF_BACKEND_SOURCE
          )
        }
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
          terraform_init
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
          terraform_init
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
          terraform_init
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

      def refresh
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.source_path, working_folder
        ensure_state_folder
        Dir.chdir(working_folder) do
          terraform_init
          RubyTerraform.refresh(terraform_command_parameters(force: true))
        end
      end


      def terraform_init
        RubyTerraform.init(terraform_init_params)
      end

      def init_dry
        init_command = RubyTerraform::Commands::Init.new
        command_line_builder = init_command.instantiate_builder
        configured_command = init_command.configure_command(
          command_line_builder,
          terraform_init_params
        )
        built_command = configured_command.build
        "cd #{working_folder} && #{built_command.to_s}"
      end

      def terraform_init_params
        if configuration.has_remote_state_configuration?
          {
            backend: 'true',
            backend_config: backend_parameters
          }
        else
          {}
        end
      end

      def ensure_state_folder
        if configuration.has_local_state_configuration?
          Instance.ensure_folder(configuration.terraform_backend['statefile_folder'])
        end
      end

      def terraform_command_parameters(added_parameters = {})
        {
          vars: terraform_variables
        }.merge(local_state_parameters).merge(added_parameters)
      end

      def terraform_variables
        parameter_values.merge(resource_values) { |key, oldval, newval|
          raise "Duplicate values for terraform variable '#{key}' ('#{oldval}' and '#{newval}')"
        }.merge({ 'instance_identifier' => id })
      end

      def local_state_parameters
        if configuration.has_local_state_configuration?
          { state: configuration.local_statefile }
        else
          {}
        end
      end

      def backend_parameters
        if configuration.has_remote_state_configuration?
          configuration.terraform_backend
        else
          {}
        end
      end

    end
  end
end
