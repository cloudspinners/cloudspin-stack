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

      def self.from_location(definition_location, definition_cache_folder: '.cloudspin/definitions')
        if RemoteDefinition.is_remote?(definition_location)
          # puts "INFO: Downloading remote stack definition"
          from_file(RemoteDefinition.new(definition_location).fetch(definition_cache_folder), from_remote: true)
        else
          # puts "INFO: Using local stack definition source"
          from_file(definition_location)
        end
      end

      def is_from_remote?
        @from_remote
      end

    end

    class NoStackDefinitionConfigurationFileError < StandardError; end

  end
end
