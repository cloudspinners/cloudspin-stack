require 'thor'
require 'cloudspin/stack'

module Cloudspin

  class CLI < Thor

    class_option :file,
      :aliases => '-f',
      :banner => 'YAML-CONFIG-FILE',
      :type => :array,
      :default => ['stack-instance-defaults.yaml', 'stack-instance-local.yaml'],
      :desc => 'A list of configuration files to load for the stack instance. Values in files listed later override those from earlier files.'

    class_option :terraform_source,
      :aliases => '-t',
      :banner => 'PATH',
      :default => './src',
      :desc => 'Folder with the terraform project source files'

    class_option :work,
      :aliases => '-w',
      :banner => 'PATH',
      :default => './work',
      :desc => 'Folder to create and copy working files into'

    class_option :state,
      :aliases => '-s',
      :banner => 'PATH',
      :default => './state',
      :desc => 'Folder to create and store local state'

    desc 'up INSTANCE_ID', 'Create or update the stack instance'
    option :dry, :type => :boolean, :default => false
    option :plan, :type => :boolean, :default => false
    def up(id)
      if options[:plan] && options[:dry]
        puts instance(id).plan_dry
      elsif options[:plan] && ! options[:dry]
        puts instance(id).plan
      elsif ! options[:plan] && options[:dry]
        puts instance(id).up_dry
      else
        instance(id).up
      end
    end

    desc 'down INSTANCE_ID', 'Destroy the stack instance'
    option :dry, :type => :boolean, :default => false
    option :plan, :type => :boolean, :default => false
    def down(id)
      if options[:plan] && options[:dry]
        puts instance(id).plan_dry(plan_destroy: true)
      elsif options[:plan] && ! options[:dry]
        puts instance(id).plan(plan_destroy: true)
      elsif ! options[:plan] && options[:dry]
        puts instance(id).down_dry
      else
        instance(id).down
      end
    end

    desc 'version', 'Print the version number'
    def version
      puts "cloudspin-stack: #{Cloudspin::Stack::VERSION}"
    end

    desc 'info', 'Print some info about arguments, for debugging'
    def info
      puts "Configuration file: #{options[:file]}"
    end

    no_commands do

      def instance(id)
        stack = Cloudspin::Stack::Instance.new(
          id: id,
          stack_definition: stack_definition,
          backend_config: {},
          working_folder: options[:work],
          statefile_folder: options[:state]
        )
        options[:file].each { |config_file|
          stack.add_config_from_yaml(config_file)
        }
        stack.add_parameter_values({ :deployment_identifier => id })
        stack
      end

      def stack_definition
        Cloudspin::Stack::Definition.from_file(options[:terraform_source] + '/stack-definition.yaml')
      end

    end

    def self.exit_on_failure?
      true
    end

  end

end

