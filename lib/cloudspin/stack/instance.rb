require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class Instance

      include FileUtils

      attr_reader :working_folder,
          :backend_config,
          :statefile_folder,
          :parameter_values,
          :resource_values

      def initialize(stack_definition:,
                     backend_config:,
                     working_folder:,
                     statefile_folder:,
                     parameter_values: {},
                     resource_values: {})
        @stack_definition = stack_definition
        @backend_config = backend_config
        @working_folder = working_folder
        @statefile_folder = statefile_folder
        @parameter_values = parameter_values
        @resource_values = resource_values
      end

      def plan
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: backend_config)
          RubyTerraform.plan(
            state: terraform_statefile,
            vars: terraform_variables
          )
        end
      end

      def plan_command
        options = {
          :state => terraform_statefile,
          :vars => terraform_variables
        }
        plan_command = RubyTerraform::Commands::Plan.new
        command_line_builder = plan_command.instantiate_builder
        configured_command = plan_command.configure_command(command_line_builder, options)
        built_command = configured_command.build
        built_command.to_s
      end

      def up
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: backend_config)
          RubyTerraform.apply(
            auto_approve: true,
            state: terraform_statefile,
            vars: terraform_variables
          )
        end
      end

      def down
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: backend_config)
          RubyTerraform.destroy(
            force: true,
            state: terraform_statefile,
            vars: terraform_variables
          )
        end
      end

      def terraform_variables
        @parameter_values.merge(@resource_values) { |key, oldval, newval|
          raise "Duplicate values for terraform variable '#{key}' ('#{oldval}' and '#{newval}')"
        }
      end

      def terraform_statefile
        statefile_folder + "/default_name.tfstate"
      end

    end
  end
end
