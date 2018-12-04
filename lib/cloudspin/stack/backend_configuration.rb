require 'ruby_terraform'
require 'fileutils'

module Cloudspin
  module Stack
    class BackendConfiguration

      attr_reader :local_state_folder
      attr_reader :local_statefile

      def initialize(
                      terraform_backend_configuration_values:,
                      instance_identifier:,
                      stack_name:,
                      base_folder:
                    )
        @terraform_backend_configuration_values  = terraform_backend_configuration_values
        @instance_identifier  = instance_identifier
        @stack_name           = stack_name
        @base_folder          = base_folder

        @has_remote_state = configure_for_remote_backend
        @has_local_state = configure_for_local_backend
      end

      def configure_for_remote_backend
        if @terraform_backend_configuration_values['bucket'].nil?
          # puts "DEBUG: Not using remote state"
          false
        else
          # puts "DEBUG: Using remote state"
          @terraform_backend_configuration_values['key'] = default_state_key
          true
        end
      end

      def configure_for_local_backend
        @local_state_folder = "#{@base_folder}/state/#{@instance_identifier}"
        @local_statefile = "#{@local_state_folder}/#{@instance_identifier}.tfstate"
        if @has_remote_state && ! File.exists?(@local_statefile)
          @local_state_folder = nil
          @local_statefile = nil
          # puts "DEBUG: Not using local state"
          false
        else
          # puts "DEBUG: Using local state"
          true
        end
      end

      def prepare(working_folder:)
        if remote_state?
          add_backend_terraform_file_to(working_folder)
          # puts "DEBUG: Prepare for use of remote state"
        end

        if local_state?
          # puts "DEBUG: Prepare to use local state"
          create_local_state_folder
        end

        if migrate_state?
          # puts "DEBUG: Prepare to migrate state from local to remote"
          copy_statefile_to(working_folder)
        end
      end

      def add_backend_terraform_file_to(working_folder)
        # puts "DEBUG: Creating file #{working_folder}/_cloudspin_backend.tf"
        File.open("#{working_folder}/_cloudspin_backend.tf", 'w') { |backend_file|
          backend_file.write(<<~TF_BACKEND_SOURCE
            terraform {
              backend "s3" {}
            }
          TF_BACKEND_SOURCE
          )
        }
      end

      def create_local_state_folder
        # puts "DEBUG: backend_configuration.create_local_state_folder: #{@local_state_folder}"
        FileUtils.mkdir_p @local_state_folder
        # Pathname.new(@local_state_folder).realdirpath.to_s
      end

      def copy_statefile_to(working_folder)
        FileUtils.copy(@local_statefile, "#{working_folder}/terraform.tfstate")
      end

      def default_state_key
        "#{@instance_identifier}.tfstate"
      end

      def terraform_init_parameters
        if remote_state?
          {
            backend: 'true',
            force_copy: migrate_state?,
            backend_config: @terraform_backend_configuration_values
          }
        else
          {}
        end
      end

      def terraform_command_parameters
        if local_state? && !migrate_state?
          {
            :state => @local_statefile
          }
        else
          {}
        end
      end

      def remote_state?
        @has_remote_state
      end

      def local_state?
        @has_local_state
      end

      def migrate_state?
        remote_state? && local_state?
      end

    end
  end
end

