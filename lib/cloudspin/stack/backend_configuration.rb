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

        @has_remote_state         = ! @terraform_backend_configuration_values['bucket'].nil?

        if @has_remote_state
          # puts "DEBUG: Using remote state"
          @local_state_folder = nil
          @local_statefile = nil
          @terraform_backend_configuration_values['key'] = default_state_key
          @migrate_state = initialize_migrate_flag
        else
          # puts "DEBUG: Not using remote state"
          @migrate_state = false
        end

        if !@has_remote_state || @migrate_state
          @local_state_folder = intialize_state_folder
          @local_statefile = "#{@local_state_folder}/#{@instance_identifier}.tfstate"
          # puts "DEBUG: Local statefile: #{@local_statefile}"
          # puts "DEBUG: Migrating? #{@migrate_state}"
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

      def intialize_state_folder
        # TODO: Prefer to not actually create the folder, but seemed necessary to build the full path string.
        FileUtils.mkdir_p "#{@base_folder}/state"
        Pathname.new("#{@base_folder}/state/#{@instance_identifier}").realdirpath.to_s
      end

      def initialize_migrate_flag
        if @terraform_backend_configuration_values['migrate'].nil?
          false
        else
          migrate_value = @terraform_backend_configuration_values.delete('migrate')
          migrate_value.to_s.downcase == 'true'
        end
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

