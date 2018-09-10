
RSpec.describe 'Stack::Instance' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'my_stack')
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      id: 'test_stack_instance',
      stack_definition: stack_definition,
      backend_config: {},
      working_folder: working_folder,
      statefile_folder: statefile_folder,
      configuration: instance_configuration
    )
  }

  let(:instance_configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(stack_definition)
      .add_values(configuration_values)
  }

  let(:working_folder) { Dir.mktmpdir }
  let(:statefile_folder) { Dir.mktmpdir }

  let(:source_path) {
    src = Dir.mktmpdir
    File.write("#{src}/main.tf", '# Empty terraform file')
    src
  }

  let(:configuration_values) {
    {
      'parameter_values' => {
        'x' => '9',
        'y' => '8'
      },
      'resource_values' => {
        'a' => '1',
        'b' => '2'
      }
    }
  }

  it 'has the expected stack_identifier' do
    expect(stack_instance.id).to eq('test_stack_instance')
  end

  it 'is planned without error' do
    expect { stack_instance.plan }.not_to raise_error
  end

  it 'returns a reasonable-looking plan command' do
    expect( stack_instance.plan_dry ).to match(/terraform plan/)
  end

  it 'includes the instance parameters in the terraform command' do
    expect( stack_instance.plan_dry ).to match(/-var 'x=9'/)
    expect( stack_instance.plan_dry ).to match(/-var 'y=8'/)
  end

  it 'includes the required resources in the terraform command' do
    expect( stack_instance.plan_dry ).to match(/-var 'a=1'/)
    expect( stack_instance.plan_dry ).to match(/-var 'b=2'/)
  end

end
