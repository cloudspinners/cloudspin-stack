require 'thor'
require 'cloudspin/stack'

module Cloudspin
  class CLI < Thor

    desc 'plan', 'Print the changes that will by applied when the \'stack up\' command is run'
    def plan
      instance.plan
    end

    no_commands do
      def instance
        Cloudspin::Stack::Instance.new(
          stack_definition: stack_definition,
          backend_config: {},
          working_folder: working_folder,
          statefile_folder: statefile_folder,
          instance_parameter_values: instance_parameter_values,
          required_resource_values: required_resource_values
        )
      end

      def stack_definition
        Cloudspin::Stack::Definition.from_file(terraform_source_folder + '/stack.yaml')
      end

      def stack_project_folder
        Pathname.new(Dir.pwd).realpath.to_s
      end

      def terraform_source_folder
        Pathname.new(stack_project_folder + '/src').realpath.to_s
      end

      def working_folder
        Pathname.new(stack_project_folder + '/work').realpath.to_s
      end

      def statefile_folder
        Pathname.new(stack_project_folder + '/state').realpath.to_s
      end

      def instance_parameter_values
        {
          'deployment_identifier' => 'my_env',
          'component' => 'my_component',
          'estate' => 'my_estate',
          'base_dns_domain' => 'my_domain'
        }
      end

      def required_resource_values
        {
          'assume_role_arn' => assume_role_arn
        }
      end

      def assume_role_arn
        configuration['assume_role_arn']
      end

      def configuration
        @config ||= load_config
      end

      def load_config
        default_config.merge(local_config)
      end

      def local_config
        YAML.load_file(stack_project_folder + '/spin-local.yaml') || {}
      end

      def default_config
        YAML.load_file(stack_project_folder + '/spin-default.yaml') || {}
      end

    end

    def self.exit_on_failure?
      true
    end

  end
end
