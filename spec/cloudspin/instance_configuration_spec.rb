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

    it 'sets a local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to_not be_empty
    end

    it 'sets the expected local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to match /\/state\/a_name$/
    end
  end

  describe 'with a single set of configuration' do
    let(:instance_configuration_values) {
      {
        'instance' => { 'option' => 'value_x' },
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
  end

  describe 'with overridden values' do
    let(:first_config) {
      {
        'instance' => { 'option' => 'first_set' },
        'parameters' => { 'option' => 'first_set' }
      }
    }
    let(:second_config) {
      {
        'parameters' => { 'option' => 'second_set' },
        'resources' => { 'option' => 'second_set' }
      }
    }
    let(:configuration) {
      Cloudspin::Stack::InstanceConfiguration.new(
        configuration_values: first_config.merge(second_config),
        stack_definition: stack_definition,
        base_folder: base_folder
      )
    }

    it 'the first value is used if it\'s the only one' do
      expect(configuration.instance_values['option']).to eq('first_set')
    end

    it 'the second value is used if it\'s the only one' do
      expect(configuration.resource_values['option']).to eq('second_set')
    end

    it 'the second value overrides the first if both are set' do
      expect(configuration.parameter_values['option']).to eq('second_set')
    end
  end

  describe 'with stack name set in the stack definition' do
    let(:stack_definition) {
      Cloudspin::Stack::Definition.new(
        source_path: '/some/path',
        stack_name: 'a_name'
      )
    }

    let(:instance_configuration_values) {{}}

    it 'is set in the instance configuration' do
      expect(configuration.stack_name).to eq('a_name')
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
        'instance' => { 'identifier' => 'overridden_identifier' },
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

  describe 'with terraform backend configured' do
    let(:terraform_config) {
      {
        'terraform_backend' => { 'bucket' => 'the_bucket' }
      }
    }
    let(:configuration) {
      Cloudspin::Stack::InstanceConfiguration.new(
        configuration_values: terraform_config,
        stack_definition: stack_definition,
        base_folder: base_folder
      )
    }

    it 'does not set a local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to be_nil
    end

    it 'sets the bucket' do
      expect(configuration.terraform_backend['bucket']).to eq('the_bucket')
    end

    it 'sets the key' do
      expect(configuration.terraform_backend['key']).to eq('/a_name.tfstate')
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
