RSpec.describe 'Stack::Instance' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'my_stack')
  }

  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    mkdir_p "#{folder}/state"
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
      base_folder: base_folder,
      configuration_values: instance_configuration_values
    )
  }

  let(:instance_configuration_values) {
    {
      'terraform_backend' => terraform_backend_configuration
    }
  }

  describe 'with remote backend and an existing local statefile' do

    let!(:statefile) do
      mkdir_p "#{base_folder}/state/my_stack"
      touch "#{base_folder}/state/my_stack/my_stack.tfstate"
    end

    let(:terraform_backend_configuration) {
      {
        'bucket' => 'dummy_bucket_name'
      }
    }

    it 'knows we want to migrate the state' do
      expect(stack_instance.backend_configuration.migrate_state?).to be true
    end

    it 'creates a local state folder' do
      working_copy_folder = stack_instance.prepare
      expect(File).to be_directory(stack_instance.backend_configuration.local_state_folder)
    end

    it 'adds a backend configuration file' do
      working_copy_folder = stack_instance.prepare
      expect(File).to exist("#{working_copy_folder}/_cloudspin_backend.tf")
    end

    it 'copies the statefile to the working folder' do
      working_copy_folder = stack_instance.prepare
      expect(File).to exist("#{working_copy_folder}/terraform.tfstate")
    end

    it 'will use the -backend argument for the terraform init command' do
      expect(stack_instance.terraform_init_arguments[:backend]).to_not be_nil
    end

    it 'renames the local statefile after migration' do
      working_copy_folder = stack_instance.prepare
      stack_instance.after
      expect(File).to_not exist("#{base_folder}/state/my_stack/my_stack.tfstate")
      expect(File).to exist("#{base_folder}/state/my_stack/my_stack.tfstate.migrated")
    end

  end

end
