require 'thor'
require 'cloudspin/stack'

module Cloudspin

  class CLI < Thor

    class_option :file,
      :aliases => '-f',
      :banner => 'YAML-CONFIG-FILE',
      :type => :array,
      :default => [
        Util.full_path_to('spin-default.yaml'),
        Util.full_path_to('spin-local.yaml')
      ],
      :desc => 'A list of configuration files to load for the stack instance. Values in files listed later override those from earlier files.'

    class_option :terraform_source,
      :aliases => '-t',
      :banner => 'PATH',
      :default => Util.full_path_to('./src'),
      :desc => 'Folder with the terraform project source files'

    class_option :work,
      :aliases => '-w',
      :banner => 'PATH',
      :default => Util.full_path_to('./work'),
      :desc => 'Folder to create and copy working files into'

    class_option :state,
      :aliases => '-s',
      :banner => 'PATH',
      :default => Util.full_path_to('./state'),
      :desc => 'Folder to create and store local state'

    desc 'plan', 'Print the changes that will by applied when the \'up\' command is run'
    option :dry, :type => :boolean, :default => false
    def plan
      if options[:dry]
        puts instance.plan_dry
      else
        instance.plan
      end
    end

    desc 'up', 'Create or update the stack instance'
    option :dry, :type => :boolean, :default => false
    def up
      if options[:dry]
        puts instance.up_dry
      else
        instance.up
      end
    end

    desc 'down', 'Destroy the stack instance'
    def down
      instance.down
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

