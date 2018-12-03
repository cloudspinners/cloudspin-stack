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
      :banner => 'PATH-OR-URL',
      :desc => 'Path to terraform project source files. Defaults to ./src'

    class_option :environment,
      :aliases => '-e',
      :banner => 'environment_id',
      :desc => 'An environment instance to manage. File ./environments/stack-instance-ENVIRONMENT_ID.yaml must exist.'

    desc 'up', 'Create or update the stack instance'
    option :dry, :type => :boolean, :default => false
    option :plan, :type => :boolean, :default => false
    option :'show-init', :type => :boolean, :default => true
    def up
      puts terraform_runner.init_dry if options[:'show-init']
      if options[:plan] && options[:dry]
        puts terraform_runner.plan_dry
      elsif options[:plan] && ! options[:dry]
        instance.prepare
        puts terraform_runner.plan
      elsif ! options[:plan] && options[:dry]
        puts terraform_runner.up_dry
      else
        instance.prepare
        terraform_runner.up
      end
    end

    desc 'prepare', 'Prepare the working folder and backend for the stack instance'
    option :'show-init', :type => :boolean, :default => true
    def prepare
      instance.prepare
      puts terraform_runner.init_dry if options[:'show-init']
      puts terraform_runner.init
      puts "Working folder prepared: #{instance.working_folder}"
      puts "Ready:\ncd #{instance.working_folder} && terraform apply"
    end

    desc 'down', 'Destroy the stack instance'
    option :dry, :type => :boolean, :default => false
    option :plan, :type => :boolean, :default => false
    option :'show-init', :type => :boolean, :default => true
    def down
      puts terraform_runner.init_dry if options[:'show-init']
      if options[:plan] && options[:dry]
        puts terraform_runner.plan_dry(plan_destroy: true)
      elsif options[:plan] && ! options[:dry]
        instance.prepare
        puts terraform_runner.plan(plan_destroy: true)
      elsif ! options[:plan] && options[:dry]
        puts terraform_runner.down_dry
      else
        instance.prepare
        terraform_runner.down
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
        Cloudspin::Stack::Instance.from_folder(
          instance_configuration_files,
          definition_location: options[:source],
          base_folder: '.',
          base_working_folder: './work'
        )
      end

      def terraform_runner
        Cloudspin::Stack::Terraform.new(
          working_folder: instance.working_folder,
          terraform_variables: instance.terraform_variables,
          terraform_init_arguments: instance.terraform_init_arguments
        )
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

