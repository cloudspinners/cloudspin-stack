require 'webmock/rspec'

RSpec.describe 'Stack::Definition' do

  let(:dummy_zipfile) { dummy_definition_artefact }
  let(:local_definitions_folder) { Dir.mktmpdir('temp_local_definitions') }

  before(:each) {
    stub_request(:any, /cloudspin.io/).to_return(body: File.new(dummy_zipfile), status: 200)
  }

  describe 'downloaded from an http URL' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.from_location(
        'http://cloudspin.io/dummies/archive.zip',
        definition_cache_folder: local_definitions_folder
      )
    }

    it 'ends up in the expected local folder' do
      expect(stack_definition.source_path).to eq(local_definitions_folder + '/.')
    end

    it 'puts the definition spec in the expected location' do
      stack_definition
      expect(File.exists?(local_definitions_folder + '/stack-definition.yaml')).to be(true)
    end
  end

  describe 'artefact defined through stack arguments' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.from_location(
        stack_configuration: { 'definition_location' => 'http://cloudspin.io/dummies/archive.zip' },
        definition_cache_folder: local_definitions_folder
      )
    }

    it 'ends up in the expected local folder' do
      expect(stack_definition.source_path).to eq(local_definitions_folder + '/.')
    end

  end


end

