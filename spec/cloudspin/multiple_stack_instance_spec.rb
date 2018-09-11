
RSpec.describe 'Multiple Stack::Instance/s' do

  let(:base_working_folder) { Dir.mktmpdir(['cloudspin-', '-work']) }
  let(:base_statefile_folder) { Dir.mktmpdir(['cloudspin-', '-state']) }

  let(:source_path) {
    src = Dir.mktmpdir
    File.write("#{src}/main.tf", '# Empty terraform file')
    src
  }

  let(:first_config_file) {
    tmp = Tempfile.new('first_instance_config.yaml')
    tmp.write(<<~FIRST_YAML_FILE
      ---
      instance:
        group: one
      parameters:
        environment_name: one
      FIRST_YAML_FILE
    )
    tmp.close
    tmp.path
  }

  let(:second_config_file) {
    tmp = Tempfile.new('second_instance_config.yaml')
    tmp.write(<<~SECOND_YAML_FILE
      ---
      instance:
        group: two
      parameters:
        environment_name: two
      SECOND_YAML_FILE
    )
    tmp.close
    tmp.path
  }

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'empty_stack')
  }

  let(:stack_instance_one) {
    Cloudspin::Stack::Instance.from_files(
      first_config_file,
      stack_definition: stack_definition,
      base_working_folder: base_working_folder,
      base_statefile_folder: base_statefile_folder
    )
  }

  let(:stack_instance_two) {
    Cloudspin::Stack::Instance.from_files(
      second_config_file,
      stack_definition: stack_definition,
      base_working_folder: base_working_folder,
      base_statefile_folder: base_statefile_folder
    )
  }

  describe 'first instance created from file' do
    it 'has the expected id' do
      expect(stack_instance_one.id).to eq('empty_stack-one')
    end
  end

  describe 'second instance created from file' do
    it 'has the expected id' do
      expect(stack_instance_two.id).to eq('empty_stack-two')
    end
  end

  describe 'both instances' do
    it 'have different ids' do
      expect(stack_instance_two.id).to_not eq(stack_instance_one.id)
    end
  end

end
