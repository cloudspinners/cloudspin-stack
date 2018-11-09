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

  let(:instance_config_file) {
    temporary_yaml_file('stack-instance-configuration.yaml',
      <<~INSTANCE_CONFIGURATION
      ---
      stack:
        name: example_stack
        definition_location: 'https://localhost/example-stack.zip'
      INSTANCE_CONFIGURATION
    )
  }

  let(:definition_location) {
    'https://localhost/example-stack.zip'
  }

  let(:dummy_base_folder) { Dir.mktmpdir('dummy_base_folder') }

  let(:dummy_zipfile) { dummy_definition_artefact }

  before(:each) {
    stub_request(:any, /localhost/).to_return(body: File.new(dummy_zipfile), status: 200)
  }

  describe 'loaded from a folder' do
    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('example_stack')
    end
  end

end

