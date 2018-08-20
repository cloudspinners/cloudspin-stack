
RSpec.describe 'Stack instance' do

  let(:source_folder) {
    src = Dir.mktmpdir
    File.write("#{src}/main.tf", '# Empty terraform file')
    src
  }

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(terraform_source_path: source_folder)
  }

  let(:working_folder) { Dir.mktmpdir }

  let(:statefile_folder) { Dir.mktmpdir }

  let(:instance_parameter_values) {
    {
      'x' => '9',
      'y' => '8'
    }
  }

  let(:required_resource_values) {
    {
      'a' => '1',
      'b' => '2'
    }
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      stack_definition: stack_definition,
      backend_config: {},
      working_folder: working_folder,
      statefile_folder: statefile_folder,
      instance_parameter_values: instance_parameter_values,
      required_resource_values: required_resource_values)
  }

  it 'is planned without error' do
    expect { stack_instance.plan }.not_to raise_error
  end

  it 'returns a reasonable-looking plan command' do
    expect( stack_instance.plan_command ).to match(/terraform plan/)
  end

  it 'includes the instance parameters in the terraform command' do
    expect( stack_instance.plan_command ).to match(/-var 'x=9'/)
    expect( stack_instance.plan_command ).to match(/-var 'y=8'/)
  end

  it 'includes the required resources in the terraform command' do
    expect( stack_instance.plan_command ).to match(/-var 'a=1'/)
    expect( stack_instance.plan_command ).to match(/-var 'b=2'/)
  end

end
