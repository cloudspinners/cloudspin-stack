require 'thor'
require 'cloudspin/stack'

module Cloudspin

  class CLI < Thor

    class_option :file,
      :aliases => '-f',
      :banner => 'YAML-CONFIG-FILE',
      :type => :array,
      :default => ['stack-instance-defaults.yaml', 'stack-instance-local.yaml'],
      :desc => 'A list of stack instance configuration files. Values in files listed later override those from earlier files.'

    class_option :source,
      :aliases => '-s',
      :banner => 'PATH',
      :default => './src',
      :desc => 'Folder with the terraform project source files'

    class_option :environment,
      :aliases => '-e',
      :banner => 'YAML-CONFIG-FILE',
      :desc => 'An environment instance to manage.'

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
      puts "Configuration files: #{instance_configuration_files}"
    end

    no_commands do

      def instance
        Cloudspin::Stack::Instance.from_files(
          instance_configuration_files,
          stack_definition: stack_definition,
          backend_config: {},
          working_folder: options[:work],
          statefile_folder: options[:state]
        )
      end

      def stack_definition
        Cloudspin::Stack::Definition.from_file(options[:terraform_source] + '/stack-definition.yaml')
      end

      def instance_configuration_files
        file_list = options[:file]
        if options[:environment]
          if File.exists? environment_config_file
            file_list << environment_config_file
          else
            $stderr.puts "Missing configuration file for environment #{options[:environment]} (#{environment_config_file})"
            exit 1
          end
        end
        file_list
      end

      def environment_config_file
        Pathname.new("./environments/stack-instance-#{options[:environment]}.yaml").realdirpath.to_s
      end

    end

    def self.exit_on_failure?
      true
    end

  end

end

