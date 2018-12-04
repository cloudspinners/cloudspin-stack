require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class Terraform

      # KSM: Maybe this should be a static class - pass in the working directory and
      # the arguments, and call them. All the logic of assembling the command line
      # arguments should be in the caller?? Since I want the caller to be able to
      # spit out the things in a variables file, for instance.
      def initialize(
        working_folder: '.',
        terraform_variables: {},
        terraform_init_arguments: {}
      )
        @working_folder = working_folder
        # @terraform_variables = terraform_variables
        @terraform_variables = {}
        @terraform_init_arguments = terraform_init_arguments
      end

      def plan(plan_destroy: false)
        Dir.chdir(@working_folder) do
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
        "cd #{@working_folder} && #{built_command.to_s}"
      end

      def up
        Dir.chdir(@working_folder) do
          terraform_init
          RubyTerraform.apply(terraform_command_parameters(auto_approve: true))
        end
      end

      def up_dry
        up_command = RubyTerraform::Commands::Apply.new
        command_line_builder = up_command.instantiate_builder
        configured_command = up_command.configure_command(command_line_builder, terraform_command_parameters)
        built_command = configured_command.build
        "cd #{@working_folder} && #{built_command.to_s}"
      end

      def down
        Dir.chdir(@working_folder) do
          terraform_init
          RubyTerraform.destroy(terraform_command_parameters(force: true))
        end
      end

      def down_dry
        down_command = RubyTerraform::Commands::Destroy.new
        command_line_builder = down_command.instantiate_builder
        configured_command = down_command.configure_command(command_line_builder, terraform_command_parameters)
        built_command = configured_command.build
        "cd #{@working_folder} && #{built_command.to_s}"
      end

      def refresh
        Dir.chdir(@working_folder) do
          terraform_init
          RubyTerraform.refresh(terraform_command_parameters(force: true))
        end
      end

      def terraform_init
        RubyTerraform.init(@terraform_init_arguments)
      end

      def init
        Dir.chdir(@working_folder) do
          terraform_init
        end
      end

      def init_dry
        init_command = RubyTerraform::Commands::Init.new
        command_line_builder = init_command.instantiate_builder
        configured_command = init_command.configure_command(
          command_line_builder,
          @terraform_init_arguments
        )
        built_command = configured_command.build
        "cd #{@working_folder} && #{built_command.to_s}"
      end

      # KSM: Do we have this here, or do we munge all this up in the calling method and 
      # just pass in the processed list of arguments?
      # For that matter, should we just call each of the actions on this class as static
      # methods? Does this class really need to hold any kind of state?

      def terraform_command_parameters(added_parameters = {})
        {
          vars: @terraform_variables
        }.merge(added_parameters)
      end

    end
  end
end

