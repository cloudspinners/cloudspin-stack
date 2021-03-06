require 'webmock/rspec'

RSpec.describe 'Stack::Definition' do

  describe 'created from code' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.new(
        source_path: '/some/path',
        stack_name: 'a_name',
        stack_version: '0.0.0-x'
      )
    }

    it 'has the expected terraform source path' do
      expect(stack_definition.source_path).to eq('/some/path')
    end

    it 'has the defined stack name' do
      expect(stack_definition.name).to eq('a_name')
    end

    it 'has the defined version' do
      expect(stack_definition.version).to eq('0.0.0-x')
    end
  end

  describe 'defined from yaml spec file' do
    let(:yaml_file) {
      tmp = Tempfile.new('stack-definition.yaml')
      tmp.write(<<~YAML_FILE
        ---
        stack:
          name: yaml_name
          version: 0.0.0-y
        YAML_FILE
      )
      tmp.close
      tmp.path
    }

    let(:stack_definition) {
      Cloudspin::Stack::Definition.from_file(yaml_file)
    }

    it 'has assumed the terraform path from the yaml file location' do
      expect(stack_definition.source_path).to eq(File.dirname(yaml_file))
    end

    it 'has the stack name defined in the yaml file' do
      expect(stack_definition.name).to eq('yaml_name')
    end

    it 'has the version defined in the yaml file' do
      expect(stack_definition.version).to eq('0.0.0-y')
    end
  end

  describe 'given an invalid location' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.from_location('ftp://foo')
    }
    it 'raises the relevant error' do
      expect { stack_definition }.to raise_error(Cloudspin::Stack::NoStackDefinitionConfigurationFileError)
    end
  end

  describe 'given a non-existent file' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.from_location('/xxx_foo')
    }
    it 'raises the relevant error' do
      expect { stack_definition }.to raise_error(Cloudspin::Stack::NoStackDefinitionConfigurationFileError)
    end
  end

  describe 'defined from local folder' do
    let(:yaml_file) {
      dummy_definition_specfile(
        <<~YAML_FILE
        ---
        stack:
          name: yaml_name
          version: 0.0.0-y
        YAML_FILE
      )
    }

    let(:stack_definition) {
      Cloudspin::Stack::Definition.from_location(File.dirname(yaml_file))
    }

    it 'has assumed the terraform path from the yaml file location' do
      expect(stack_definition.source_path).to eq(File.dirname(yaml_file))
    end
  end

end

