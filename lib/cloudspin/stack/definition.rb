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
        # stack_spec = symbolize(spec_hash)
        self.new(
          source_path: source_path,
          stack_name: spec_hash.dig('stack', 'name'),
          stack_version: spec_hash.dig('stack', 'version')
        )
      end

      # private

      # def self.symbolize(obj)
      #     return obj.inject({}){ |memo, (k,v)|
      #       memo[k.to_sym] = symbolize(v)
      #       memo
      #     } if obj.is_a? Hash
      #     return obj.inject([]) { |memo, v|
      #       memo << symbolize(v)
      #       memo
      #     } if obj.is_a? Array
      #     return obj
      # end

    end

    class NoStackDefinitionConfigurationFile < StandardError; end

  end
end
