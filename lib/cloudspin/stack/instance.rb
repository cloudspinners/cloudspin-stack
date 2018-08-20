require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class Instance

      include FileUtils

      attr_reader :working_folder, :backend_config, :statefile_folder

      def initialize(stack_definition:,
                     backend_config:,
                     working_folder:,
                     statefile_folder:,
                     variable_values: {})
        @stack_definition = stack_definition
        @backend_config = backend_config
        @working_folder = working_folder
        @statefile_folder = statefile_folder
        @variable_values = variable_values
      end

      def plan
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
        RubyTerraform.init(backend_config: backend_config)
        RubyTerraform.plan(
          state: terraform_statefile,
          vars: terraform_variables)
        end
      end

      def plan_dry
        options = {
          :state => terraform_statefile,
          :vars => terraform_variables
        }
        plan_command = RubyTerraform::Commands::Plan.new
        command_line_builder = plan_command.instantiate_builder
        configured_command = plan_command.configure_command(command_line_builder, options)
        built_command = configured_command.build
puts "KSM: built_command = #{built_command}"
        built_command.to_s
      end

      # def up
      # end

      # def down
      # end

      # def status
      # end

      def terraform_variables
        @variable_values
      end

      def terraform_statefile
        statefile_folder + "/default_name.tfstate"
      end

    end
  end
end
