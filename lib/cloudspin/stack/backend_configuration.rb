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

        configure_for_remote_backend
        configure_to_migrate_backend
        configure_for_local_backend
      end

      def configure_for_remote_backend
        @has_remote_state = if @terraform_backend_configuration_values['bucket'].nil?
          false
        else
          # puts "DEBUG: Using remote state"
          @local_state_folder = nil
          @local_statefile = nil
          @terraform_backend_configuration_values['key'] = default_state_key
          true
        end
      end

      def configure_to_migrate_backend
        @migrate_state = if @terraform_backend_configuration_values['migrate'].nil?
          false
        else
          migrate_value = @terraform_backend_configuration_values.delete('migrate')
          migrate_value.to_s.downcase == 'true'
        end
      end

      def configure_for_local_backend
        if !@has_remote_state || @migrate_state
          # puts "DEBUG: Not using remote state, or else is migrating state"
          @local_state_folder = "#{@base_folder}/state/#{@instance_identifier}"
          @local_statefile = "#{@local_state_folder}/#{@instance_identifier}.tfstate"
        end
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
        if remote_state?
          {}
        else
          {
            :state => @local_statefile
          }
        end
      end

      def prepare
        if remote_state?
          # puts "DEBUG: Prepare for use of remote state"
        else
          # puts "DEBUG: Prepare for use of local state"
          create_local_state_folder
        end
      end

      def create_local_state_folder
        # puts "DEBUG: backend_configuration.create_local_state_folder: #{@local_state_folder}"
        FileUtils.mkdir_p @local_state_folder
        # Pathname.new(@local_state_folder).realdirpath.to_s
      end

      def default_state_key
        "#{@instance_identifier}.tfstate"
      end

      def migrate_state?
        @migrate_state
      end

      def remote_state?
        @has_remote_state
      end

    end
  end
end

