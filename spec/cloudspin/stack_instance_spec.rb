
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

  let(:variable_values) {
    {
      'something' => 'this',
      'another' => 'that'
    }
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      stack_definition: stack_definition,
      backend_config: {},
      working_folder: working_folder,
      statefile_folder: statefile_folder,
      variable_values: variable_values)
  }

  it 'is planned without error' do
    expect { stack_instance.plan }.not_to raise_error
  end

  it 'returns a reasonable-looking plan command' do
    expect( stack_instance.plan_command ).to match(/terraform plan -var/)
  end

end
