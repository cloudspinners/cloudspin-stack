
RSpec.describe 'Stack::InstanceConfiguration' do

  let(:stack_definition) { 
      Cloudspin::Stack::Definition.new(
        source_path: '/some/path',
        stack_name: 'a_name'
      )
  }

  let(:configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(stack_definition)
      .add_values(instance_configuration_values)
  }

  describe 'with no configuration' do
    let(:instance_configuration_values) {{}} 

    it 'has the definition name as the instance_identifier' do
      expect(configuration.instance_identifier).to eq('a_name')
    end

    # it 'raises an error' do
    #   expect { configuration.instance_identifier }.to raise_error(Cloudspin::Stack::NoInstanceIdentifierError)
    # end
  end

  describe 'with a single set of configuration' do
    let(:instance_configuration_values) {
      {
        'instance_values' => { 'option' => 'value_x' },
        'parameter_values' => { 'option' => 'value_y' },
        'resource_values' => { 'option' => 'value_z' }
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

  describe 'overriding values' do
    let(:first_config) {
      {
        'instance_values' => { 'option' => 'first_set' },
        'parameter_values' => { 'option' => 'first_set' }
      }
    }
    let(:second_config) {
      {
        'parameter_values' => { 'option' => 'second_set' },
        'resource_values' => { 'option' => 'second_set' }
      }
    }
    let(:configuration) {
      Cloudspin::Stack::InstanceConfiguration.new(stack_definition).add_values(first_config).add_values(second_config)
    }

    it 'has the first value if not in the second set' do
      expect(configuration.instance_values['option']).to eq('first_set')
    end

    it 'has the second value if not in the first set' do
      expect(configuration.resource_values['option']).to eq('second_set')
    end

    it 'has the second value if in both sets' do
      expect(configuration.parameter_values['option']).to eq('second_set')
    end
  end

  describe 'stack name set in the stack definition' do
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
        'instance_values' => { 'identifier' => 'overridden_identifier' },
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

  # it 'returns a reasonable-looking plan command' do
  #   expect( stack_instance.plan_dry ).to match(/terraform plan/)
  # end

  # it 'includes the instance parameters in the terraform command' do
  #   expect( stack_instance.plan_dry ).to match(/-var 'x=9'/)
  #   expect( stack_instance.plan_dry ).to match(/-var 'y=8'/)
  # end

  # it 'includes the required resources in the terraform command' do
  #   expect( stack_instance.plan_dry ).to match(/-var 'a=1'/)
  #   expect( stack_instance.plan_dry ).to match(/-var 'b=2'/)
  # end

end
