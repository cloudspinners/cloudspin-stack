
RSpec.describe 'Stack instance' do

  let(:source_folder) {
    src = Dir.mktmpdir
    File.write("#{src}/main.tf", '# Empty terraform file')
    src
  }

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(terraform_source_path: source_folder)
  }

  let(:working_folder) { 
    Dir.mktmpdir
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      stack_definition: stack_definition,
      backend_config: {},
      working_folder: working_folder
    )
  }

  it 'is planned without error' do
    expect { stack_instance.plan }.not_to raise_error
  end

end
