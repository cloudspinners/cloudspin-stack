RSpec.describe 'Stack::InstanceConfiguration' do

  # SMELL: We shouldn't need to have a physical state folder if we don't have an instance
  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }

  let(:stack_definition) { 
    Cloudspin::Stack::Definition.new(
      source_path: '/some/path',
      stack_name: 'a_name'
    )
  }

  let(:instance_configuration_values) {{}} 

  let(:configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(
      configuration_values: instance_configuration_values,
      stack_definition: stack_definition,
      base_folder: base_folder
    )
  }

  describe 'with no configuration' do
    it 'uses the definition name as the instance_identifier' do
      expect(configuration.instance_identifier).to eq('a_name')
    end

    it 'has the expected stack name' do
      expect(configuration.stack_name).to eq('a_name')
    end

    it 'has the expected instance_identifier' do
      expect(configuration.instance_identifier).to eq('a_name')
    end
  end

  describe 'when instance configuration values are set' do
    let(:instance_configuration_values) {
      {
        'instance' => { 'option' => 'value_x', 'group' => 'some_group' },
        'parameters' => { 'option' => 'value_y' },
        'resources' => { 'option' => 'value_z' }
      }
    }

    it 'has the expected instance value' do
      expect(configuration.instance_values['option']).to eq('value_x')
    end

    it 'has the expected parameter value' do
      expect(configuration.parameter_values['option']).to eq('value_y')
    end

    it 'has the expected resource value' do
      expect(configuration.resource_values['option']).to eq('value_z')
    end

    it 'has the expected stack name' do
      expect(configuration.stack_name).to eq('a_name')
    end

    it 'has the expected instance_identifier' do
      expect(configuration.instance_identifier).to eq('a_name-some_group')
    end
  end

  describe 'with stack name overridden in the instance configuration' do
    let(:instance_configuration_values) {
      {
        'stack' => { 'name' => 'new_stack_name' }
      }
    }

    it 'has the expected stack name' do
      expect(configuration.stack_name).to eq('new_stack_name')
    end

    it 'has the expected instance_identifier' do
      expect(configuration.instance_identifier).to eq('new_stack_name')
    end
  end

  describe 'with stack name overridden in the instance configuration and group set' do
    let(:instance_configuration_values) {
      {
        'instance' => { 'group' => 'some_group' },
        'stack' => { 'name' => 'new_stack_name' }
      }
    }

    it 'has the expected stack name' do
      expect(configuration.stack_name).to eq('new_stack_name')
    end

    it 'has the expected instance_identifier' do
      expect(configuration.instance_identifier).to eq('new_stack_name-some_group')
    end
  end

  describe 'with the instance identifier explicitly set' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.new(
        source_path: '/some/path',
        stack_name: 'a_name'
      )
    }

    let(:instance_configuration_values) {
      {
        'instance' => { 'identifier' => 'overridden_identifier' }
      }
    }

    it 'is used' do
      expect(configuration.instance_identifier).to eq('overridden_identifier')
    end
  end

  describe 'without overriding the identifier' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.new(
        source_path: '/some/path',
        stack_name: 'a_name'
      )
    }

    let(:instance_configuration_values) {{}} 

    it 'uses the definition name instead' do
      expect(configuration.instance_identifier).to eq('a_name')
    end
  end

  describe 'with instance:group set' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.new(
        source_path: '/some/path',
        stack_name: 'a_name'
      )
    }

    let(:instance_configuration_values) {
      { 'instance' => { 'group' => 'a_group' } }
    }

    it 'builds the instance id from the stack name and group' do
      expect(configuration.instance_identifier).to eq('a_name-a_group')
    end
  end

  describe 'loaded from files' do
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
