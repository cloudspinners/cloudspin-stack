require 'yaml'

module Cloudspin
  module Stack
    class Definition

      attr_reader :parameter_names, :resource_names, :terraform_source_path

      def initialize(terraform_source_path: '',
                     parameter_names: [],
                     resource_names: [])
        @terraform_source_path = terraform_source_path
        @parameter_names = parameter_names
        @resource_names = resource_names
      end

      def self.from_file(specfile)
        raise "Cloudspin definition file not found: #{specfile}" unless File.exists?(specfile)
        spec_hash = YAML.load_file(specfile)
        stack_spec = symbolize(spec_hash)
        terraform_source_path = File.dirname(specfile)
        self.new(terraform_source_path: terraform_source_path, **stack_spec)
      end

      private

      def self.symbolize(obj)
          return obj.inject({}){ |memo, (k,v)|
            memo[k.to_sym] = symbolize(v)
            memo
          } if obj.is_a? Hash
          return obj.inject([]) { |memo, v|
            memo << symbolize(v)
            memo
          } if obj.is_a? Array
          return obj
      end

    end
  end
end
