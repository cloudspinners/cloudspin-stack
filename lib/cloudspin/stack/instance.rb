require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class Instance

      include FileUtils

      attr_reader :working_folder, :backend_config

      def initialize(stack_definition:,
                     backend_config:,
                     working_folder:)
        @stack_definition = stack_definition
        @backend_config = backend_config
        @working_folder = working_folder
      end

      def plan
        RubyTerraform.clean(directory: working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.terraform_source_path, working_folder
        Dir.chdir(working_folder) do
        RubyTerraform.init(backend_config: backend_config)
        RubyTerraform.plan(
          # state: terraform_statefile,
          vars: terraform_variables)
        end
      end

      # def up
      # end

      # def down
      # end

      # def status
      # end

      def terraform_variables
        {}
      end

      def terraform_statefile
        ''
      end

    end
  end
end
