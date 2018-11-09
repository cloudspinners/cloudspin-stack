RSpec.describe 'Stack::InstanceConfiguration' do

  # SMELL: We shouldn't need to have a physical state folder if we don't have an instance
  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }

  let(:stack_definition) { 
    Cloudspin::Stack::Definition.new(
      source_path: '/definition/path/src',
      stack_name: 'a_name'
    )
  }

  let(:first_file) {
    tmp = Tempfile.new('first_instance_config.yaml')
    tmp.write(<<~FIRST_YAML_FILE
      ---
      instance:
        option: first_set
      parameters:
        option: first_set
      FIRST_YAML_FILE
    )
    tmp.close
    tmp.path
  }

  let(:second_file) {
    tmp = Tempfile.new('second_instance_config.yaml')
    tmp.write(<<~SECOND_YAML_FILE
      ---
      parameters:
        option: second_set
      resources:
        option: second_set
      SECOND_YAML_FILE
    )
    tmp.close
    tmp.path
  }

  let(:configuration) {
    Cloudspin::Stack::InstanceConfiguration.from_files(first_file, second_file, stack_definition: stack_definition, base_folder: base_folder)
  }

  describe 'loaded from files' do
    it 'uses the value from the first file if it\'s only set there' do
      expect(configuration.instance_values['option']).to eq('first_set')
    end

    it 'uses the value from the second file if it\'s only set there' do
      expect(configuration.resource_values['option']).to eq('second_set')
    end

    it 'uses values from the second file if it\'s found in both files' do
      expect(configuration.parameter_values['option']).to eq('second_set')
    end

  end


end

