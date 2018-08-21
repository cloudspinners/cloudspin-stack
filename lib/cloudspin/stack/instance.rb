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
                     statefile_folder:
                    )
        @stack_definition = stack_definition
        @backend_config = backend_config
        @working_folder = working_folder
        @statefile_folder = statefile_folder
        @parameter_values = {}
        @resource_values = {}
      end

      def add_parameter_values(new_parameter_values)
        @parameter_values.merge!(new_parameter_values)
      end

      def add_resource_values(new_resource_values)
        @resource_values.merge!(new_resource_values)
      end

      def add_config_from_yaml(yaml_file)
        config = YAML.load_file(yaml_file) || {}
        add_parameter_values(config['parameters']) if config['parameters']
        add_resource_values(config['resources']) if config['resources']
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

      def plan_dry
        plan_command = RubyTerraform::Commands::Plan.new
        command_line_builder = plan_command.instantiate_builder
        configured_command = plan_command.configure_command(command_line_builder, {
          :state => terraform_statefile,
          :vars => terraform_variables
        })
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

      def up_dry
        up_command = RubyTerraform::Commands::Apply.new
        command_line_builder = up_command.instantiate_builder
        configured_command = up_command.configure_command(command_line_builder, {
          :state => terraform_statefile,
          :vars => terraform_variables
        })
        built_command = configured_command.build
        built_command.to_s
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

      def down_dry
        down_command = RubyTerraform::Commands::Destroy.new
        command_line_builder = down_command.instantiate_builder
        configured_command = down_command.configure_command(command_line_builder, {
          :state => terraform_statefile,
          :vars => terraform_variables
        })
        built_command = configured_command.build
        built_command.to_s
      end

      def down_plan
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: backend_config)
          RubyTerraform.plan(
            destroy: true,
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
