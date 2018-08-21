require 'thor'
require 'cloudspin/stack'

module Cloudspin

  class CLI < Thor

    class_option :file,
      :aliases => '-f',
      :banner => 'YAML-CONFIG-FILE',
      :type => :array,
      :default => [
        Util.full_path_from_local('spin-default.yaml'),
        Util.full_path_from_local('spin-local.yaml')
      ],
      :desc => 'A list of configuration files to load for the stack instance. Values in files listed later override those from earlier files.'

    class_option :terraform_source,
      :aliases => '-t',
      :banner => 'PATH',
      :default => Util.full_path_from_local('./src'),
      :desc => 'Folder with the terraform project source files'

    class_option :work,
      :aliases => '-w',
      :banner => 'PATH',
      :default => Util.full_path_from_local('./work'),
      :desc => 'Folder to create and copy working files into'

    class_option :state,
      :aliases => '-s',
      :banner => 'PATH',
      :default => Util.full_path_from_local('./state'),
      :desc => 'Folder to create and store local state'

    desc 'up', 'Create or update the stack instance'
    option :dry, :type => :boolean, :default => false
    option :plan, :type => :boolean, :default => false
    def up
      if options[:plan] && options[:dry]
        puts instance.plan_dry
      elsif options[:plan] && ! options[:dry]
        puts instance.plan
      elsif ! options[:plan] && options[:dry]
        puts instance.up_dry
      else
        instance.up
      end
    end

    desc 'down', 'Destroy the stack instance'
    option :dry, :type => :boolean, :default => false
    option :plan, :type => :boolean, :default => false
    def down
      if options[:plan] && options[:dry]
        puts instance.plan_dry(plan_destroy: true)
      elsif options[:plan] && ! options[:dry]
        puts instance.plan(plan_destroy: true)
      elsif ! options[:plan] && options[:dry]
        puts instance.down_dry
      else
        instance.down
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

      def instance
        stack = Cloudspin::Stack::Instance.new(
          stack_definition: stack_definition,
          backend_config: {},
          working_folder: options[:work],
          statefile_folder: options[:state]
        )
        options[:file].each { |config_file|
          stack.add_config_from_yaml(config_file)
        }
        stack
      end

      def stack_definition
        Cloudspin::Stack::Definition.from_file(options[:terraform_source] + '/stack.yaml')
      end

    end

    def self.exit_on_failure?
      true
    end

  end

end

