require 'webmock/rspec'

RSpec.describe 'Stack::Instance' do

  let(:stack_instance) {
    Cloudspin::Stack::Instance.from_folder(
      [ instance_config_file ],
      definition_location: definition_location,
      base_folder: dummy_base_folder,
      base_working_folder: "#{dummy_base_folder}/work"
    )
  }

  let(:dummy_base_folder) { Dir.mktmpdir('dummy_base_folder') }
  let(:dummy_zipfile) { dummy_definition_artefact }

  before(:each) {
    stub_request(:any, /localhost/).to_return(body: File.new(dummy_zipfile), status: 200)
  }

  describe 'loaded from a folder with an explicit location' do
    let(:instance_config_file) {
      temporary_yaml_file('stack-instance-configuration.yaml',
        <<~INSTANCE_CONFIGURATION
        ---
        stack:
          name: example_stack
        INSTANCE_CONFIGURATION
      )
    }

    let(:definition_location) { 'https://localhost/from-override.zip' }

    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('example_stack')
    end

    it 'downloads the artefact locally' do
      stack_instance
      expect(File.exists?(dummy_base_folder + '/.cloudspin/definitions/stack-definition.yaml')).to be(true)
    end
  end

  describe 'loaded from a folder with location set in configuration' do
    let(:instance_config_file) {
      temporary_yaml_file('stack-instance-configuration.yaml',
        <<~INSTANCE_CONFIGURATION
        ---
        stack:
          name: example_stack
          definition_location: 'https://localhost/from-configuration.zip'
        INSTANCE_CONFIGURATION
      )
    }

    let(:definition_location) { nil }

    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('example_stack')
    end

    it 'downloads the artefact locally' do
      stack_instance
      expect(File.exists?(dummy_base_folder + '/.cloudspin/definitions/stack-definition.yaml')).to be(true)
    end
  end

  describe 'loaded from a folder with a broken location set in configuration' do
    let(:instance_config_file) {
      temporary_yaml_file('stack-instance-configuration.yaml',
        <<~INSTANCE_CONFIGURATION
        ---
        stack:
          name: example_stack
          definition_location: 'https://brokenhost/from-configuration.zip'
        INSTANCE_CONFIGURATION
      )
    }

    let(:definition_location) { nil }

    it 'fails to download anything' do
      expect { stack_instance }.to raise_error(WebMock::NetConnectNotAllowedError)
    end
  end

  describe 'loaded from a folder with location set in configuration and explicitly' do
    let(:instance_config_file) {
      temporary_yaml_file('stack-instance-configuration.yaml',
        <<~INSTANCE_CONFIGURATION
        ---
        stack:
          name: example_stack
          definition_location: 'https://brokenhost/from-configuration.zip'
        INSTANCE_CONFIGURATION
      )
    }

    let(:definition_location) { 'https://localhost/from-override.zip' }

    it 'uses the explicit location' do
      stack_instance
      expect(File.exists?(dummy_base_folder + '/.cloudspin/definitions/stack-definition.yaml')).to be(true)
    end
  end


end

