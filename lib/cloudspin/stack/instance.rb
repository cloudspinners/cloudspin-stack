require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class Instance

      include FileUtils

      attr_reader :id,
          :working_folder,
          :backend_config,
          :statefile_folder,
          :parameter_values,
          :resource_values

      def initialize(id:,
                     stack_definition:,
                     backend_config:,
                     working_folder:,
                     statefile_folder:
                    )
        validate_id(id)
        @id = id
        @stack_definition = stack_definition
        @backend_config = backend_config
        @working_folder = working_folder
        @statefile_folder = Pathname.new(statefile_folder).realdirpath.to_s
        @parameter_values = {}
        @resource_values = {}
      end

      def self.from_definition_folder(id:, definition_folder:, instance_folder: '.')
        self.new(
          id: id,
          stack_definition: Definition.from_file(definition_folder + '/stack.yaml'),
          backend_config: {},
          working_folder: instance_folder + '/work',
          statefile_folder: instance_folder + '/state'
        )
      end

      def validate_id(raw_id)
        raise "Stack instance ID '#{raw_id}' won't work. It needs to work as a filename." if /[^0-9A-Za-z.\-\_]/ =~ raw_id
        raise "Stack instance ID '#{raw_id}' won't work. No double dots allowed." if /\.\./ =~ raw_id
        raise "Stack instance ID '#{raw_id}' won't work. First character should be a letter." if /^[^A-Za-z]/ =~ raw_id
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

      def plan(plan_destroy: false)
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
          RubyTerraform.init(backend_config: backend_config)
          RubyTerraform.plan(
            destroy: plan_destroy,
            state: terraform_statefile,
            vars: terraform_variables
          )
        end
      end

      def plan_dry(plan_destroy: false)
        plan_command = RubyTerraform::Commands::Plan.new
        command_line_builder = plan_command.instantiate_builder
        configured_command = plan_command.configure_command(command_line_builder, {
          :destroy => plan_destroy,
          :state => terraform_statefile,
          :vars => terraform_variables
        })
        built_command = configured_command.build
        "cd #{working_folder} && #{built_command.to_s}"
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
        "cd #{working_folder} && #{built_command.to_s}"
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
        "cd #{working_folder} && #{built_command.to_s}"
      end

      def terraform_variables
        @parameter_values.merge(@resource_values) { |key, oldval, newval|
          raise "Duplicate values for terraform variable '#{key}' ('#{oldval}' and '#{newval}')"
        }
      end

      def terraform_statefile
        statefile_folder + "/stack-#{id}.tfstate"
      end

    end
  end
end
