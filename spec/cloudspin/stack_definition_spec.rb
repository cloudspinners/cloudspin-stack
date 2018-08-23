require 'tempfile'

RSpec.describe 'Stack defined with defaults' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new()
  }

  it 'has the expected terraform source path' do
    expect(stack_definition.terraform_source_path).to eq('')
  end

  it 'has an empty list of instance parameter names' do
    expect(stack_definition.parameter_names).to be_empty
  end

  it 'has an empty list of required resource_names names' do
    expect(stack_definition.resource_names).to be_empty
  end

  it 'has the default stack name' do
    expect(stack_definition.name).to eq('NO_NAME')
  end

  it 'has the default version' do
    expect(stack_definition.version).to eq('0')
  end

end


RSpec.describe 'Stack defined from code' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(
      terraform_source_path: 'some/path',
      parameter_names: [ 'a', 'b'],
      resource_names: [ 'x', 'y' ],
      stack: { :name => 'a_name', :version => '0.0.0-x' }
    )
  }

  it 'has the expected terraform source path' do
    expect(stack_definition.terraform_source_path).to eq('some/path')
  end

  it 'has the defined list of instance parameter names' do
    expect(stack_definition.parameter_names).to contain_exactly('a', 'b')
  end

  it 'has the defined list of required resource_names names' do
    expect(stack_definition.resource_names).to contain_exactly('x', 'y')
  end

  it 'has the defined stack name' do
    expect(stack_definition.name).to eq('a_name')
  end

  it 'has the defined version' do
    expect(stack_definition.version).to eq('0.0.0-x')
  end

end


RSpec.describe 'Stack defined from yaml spec file' do

  let(:yaml_file) {
    tmp = Tempfile.new('stack_definition_spec.yaml')
    tmp.write(<<~YAML_FILE
      ---
      stack:
        name: yaml_name
        version: 0.0.0-y
      parameter_names:
      - foo
      - bar
      resource_names:
      - thing_one
      - thing_two
      YAML_FILE
    )
    tmp.close
    tmp.path
  }

  let(:stack_definition) {
    Cloudspin::Stack::Definition.from_file(yaml_file)
  }

  it 'has assumed the terraform path from the yaml file location' do
    expect(stack_definition.terraform_source_path).to eq(File.dirname(yaml_file))
  end

  it 'has the instance parameter names defined in the yaml file' do
    expect(stack_definition.parameter_names).to contain_exactly('foo', 'bar')
  end

  it 'has the required resource names defined in the yaml file' do
    expect(stack_definition.resource_names).to contain_exactly('thing_one', 'thing_two')
  end

  it 'has the stack name defined in the yaml file' do
    expect(stack_definition.name).to eq('yaml_name')
  end

  it 'has the version defined in the yaml file' do
    expect(stack_definition.version).to eq('0.0.0-y')
  end

end

