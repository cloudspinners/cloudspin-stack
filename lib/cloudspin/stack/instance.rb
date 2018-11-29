require 'fileutils'

module Cloudspin
  module Stack
    class Instance

      include FileUtils

      attr_reader :id, :configuration, :working_folder, :terraform_command_arguments

      def initialize(
            id:,
            stack_definition:,
            base_working_folder:,
            configuration:
      )
        validate_id(id)
        @id = id
        @stack_definition = stack_definition
        @working_folder   = base_working_folder
        @configuration    = configuration
        @terraform_command_arguments = {}
      end

      def self.from_folder(
            *instance_configuration_files,
            definition_location:,
            base_folder: '.',
            base_working_folder:
      )
        self.from_files(
            instance_configuration_files,
            stack_definition: Definition.from_location(
                definition_location,
                definition_cache_folder: "#{base_folder}/.cloudspin/definitions",
                stack_configuration: InstanceConfiguration.load_configuration_values(instance_configuration_files)['stack']
            ),
            base_folder: base_folder,
            base_working_folder: base_working_folder
          )
      end

      def self.from_files(
            *instance_configuration_files,
            stack_definition:,
            base_folder: '.',
            base_working_folder:
      )
        instance_configuration = InstanceConfiguration.from_files(
          instance_configuration_files,
          stack_definition: stack_definition,
          base_folder: base_folder
        )

        if instance_configuration.has_remote_state_configuration? && stack_definition.is_from_remote?
          # puts "DEBUG: Stack instance is configured to use remote terraform state AND remote stack definition code"
          add_backend_configuration_source(stack_definition.source_path)
        # else
        #   puts "DEBUG: Stack instance is configured to use local terraform state AND/OR local stack definition code"
        end

        self.new(
            id: instance_configuration.instance_identifier,
            stack_definition: stack_definition,
            base_working_folder: ensure_folder("#{base_working_folder}/#{instance_configuration.instance_identifier}"),
            configuration: instance_configuration
          )
      end

      def self.ensure_folder(folder)
        FileUtils.mkdir_p folder
        Pathname.new(folder).realdirpath.to_s
      end

      def self.add_backend_configuration_source(terraform_source_folder)
        # puts "DEBUG: Creating file #{terraform_source_folder}/_cloudspin_created_backend.tf"
        File.open("#{terraform_source_folder}/_cloudspin_created_backend.tf", 'w') { |backend_file|
          backend_file.write(<<~TF_BACKEND_SOURCE
            terraform {
              backend "s3" {}
            }
          TF_BACKEND_SOURCE
          )
        }
      end

      def validate_id(raw_id)
        raise "Stack instance ID '#{raw_id}' won't work. It needs to work as a filename." if /[^0-9A-Za-z.\-\_]/ =~ raw_id
        raise "Stack instance ID '#{raw_id}' won't work. No double dots allowed." if /\.\./ =~ raw_id
        raise "Stack instance ID '#{raw_id}' won't work. First character should be a letter." if /^[^A-Za-z]/ =~ raw_id
      end

      def parameter_values
        configuration.parameter_values
      end

      def resource_values
        configuration.resource_values
      end

      def prepare_working_copy
        prepare
      end

      def clean_tf_folder(folder)
        clean(folder)
      end

      def prepare
        clean(working_folder)
        mkdir_p File.dirname(working_folder)
        cp_r @stack_definition.source_path, working_folder
        ensure_state_folder
        working_folder
      end

      def clean(folder)
        FileUtils.rm_rf("#{folder}/.terraform")
      end

      # def migrate
      #   RubyTerraform.clean(directory: working_folder)
      #   mkdir_p File.dirname(working_folder)
      #   cp_r @stack_definition.source_path, working_folder
      #   Dir.chdir(working_folder) do
      #   # cp configuration.backend_configuration.local_state_folder
      #     terraform_init
      #     # terraform_state_push()
      #     RubyTerraform.plan(terraform_command_parameters)
      #   end
      # end

      # def init
        # if configuration.backend_configuration.migrate_state?
        #   prepare_state_for_migration
        # end
      # end

      # def prepare_state_for_migration
      #   # puts "DEBUG: Preparing to migrate state from #{configuration.backend_configuration.local_statefile}"
      #   cp configuration.backend_configuration.local_statefile, "#{working_folder}/terraform.tfstate"
      # end

      # TODO: Redundant? The folder is created in the BackendConfiguration class ...
      def ensure_state_folder
        if configuration.has_local_state_configuration?
          Instance.ensure_folder(configuration.backend_configuration.local_state_folder)
        end
      end

      def terraform_variables
        parameter_values.merge(resource_values) { |key, oldval, newval|
          raise "Duplicate values for terraform variable '#{key}' ('#{oldval}' and '#{newval}')"
        }.merge({ 'instance_identifier' => id })
      end

      def terraform_init_arguments
        # TODO: Unsmell these
        # (maybe backend_configuration belongs attached directly to this class?)
        configuration.backend_configuration.terraform_init_parameters
      end

      def terraform_command_arguments
        configuration.backend_configuration.terraform_command_parameters
      end

    end
  end
end
