
RSpec.describe 'Stack::Instance' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'my_stack')
  }

  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }

  let(:source_path) {
    src = Dir.mktmpdir
    File.write("#{src}/main.tf", '# Empty terraform file')
    src
  }

  let(:working_folder) {
    Dir.mktmpdir
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      id: 'test_stack_instance',
      stack_definition: stack_definition,
      base_working_folder: working_folder,
      configuration: instance_configuration
    )
  }

  let(:instance_configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(
      stack_definition: stack_definition,
      base_folder: base_folder
    )
  }

  describe 'minimal instance' do

    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('test_stack_instance')
    end

    it 'defines a working folder for the instance' do
      expect(stack_instance.working_folder).to eq("#{working_folder}")
    end

    # it 'copies the source to the working folder' do
    #   working_copy_folder = stack_instance.prepare

    # end


  end

end
