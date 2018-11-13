require 'yaml'

module Cloudspin
  module Stack
    class Definition

      attr_reader :name
      attr_reader :version
      attr_reader :source_path

      def initialize(source_path:, stack_name:, stack_version: '0', from_remote: false)
        @source_path = source_path
        @name = stack_name
        @version = stack_version
        @from_remote = from_remote
      end

      def self.from_file(specfile, from_remote: false)
        raise NoStackDefinitionConfigurationFileError, "Did not find file '#{specfile}'" unless File.exists?(specfile)
        source_path = File.dirname(specfile)
        spec_hash = YAML.load_file(specfile)
        self.new(
          source_path: source_path,
          stack_name: spec_hash.dig('stack', 'name'),
          stack_version: spec_hash.dig('stack', 'version'),
          from_remote: from_remote
        )
      end

      def self.from_location(definition_location = nil,
          definition_cache_folder: '.cloudspin/definitions',
          stack_configuration: nil
      )
        resolved_definition_location = if ! definition_location.nil?
          puts "DEBUG: definition_location has been explicitly set to #{definition_location}"
          definition_location
        elsif stack_configuration['definition_location']
          puts "DEBUG: definition_location comes from the stack configuration (#{stack_configuration})"
          stack_configuration['definition_location']
        else
          raise NoStackDefinitionConfigurationFileError, 'No location provided'
        end

        puts "DEBUG: get definition from location #{resolved_definition_location}"
        if RemoteDefinition.is_remote?(resolved_definition_location)
          puts "DEBUG: Downloading remote stack definition"
          local_definition_folder = RemoteDefinition.new(resolved_definition_location).fetch(definition_cache_folder)
          from_file("#{local_definition_folder}/stack-definition.yaml", from_remote: true)
        else
          puts "DEBUG: Using local stack definition source: #{resolved_definition_location}/stack-definition.yaml"
          from_file("#{resolved_definition_location}/stack-definition.yaml")
        end
      end

      def is_from_remote?
        @from_remote
      end

    end

    class NoStackDefinitionConfigurationFileError < StandardError; end

  end
end
