require 'yaml'

module Cloudspin
  module Stack
    class Definition

      attr_reader :name
      attr_reader :version
      attr_reader :source_path

      def initialize(source_path:, stack_name:, stack_version: '0')
        @source_path = source_path
        @name = stack_name
        @version = stack_version
      end

      def self.from_file(specfile)
        raise NoStackDefinitionConfigurationFile unless File.exists?(specfile)
        source_path = File.dirname(specfile)
        spec_hash = YAML.load_file(specfile)
        self.new(
          source_path: source_path,
          stack_name: spec_hash.dig('stack', 'name'),
          stack_version: spec_hash.dig('stack', 'version')
        )
      end

      def self.from_folder(definition_folder)
        from_file("#{definition_folder}/stack-definition.yaml")
      end

    end


    class NoStackDefinitionConfigurationFile < StandardError; end

  end
end
