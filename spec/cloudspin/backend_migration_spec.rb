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
      base_folder: base_folder,
      configuration_values: instance_configuration_values
    )
  }

  let(:instance_configuration_values) {
    {
      'terraform_backend' => terraform_backend_configuration
    }
  }

  describe 'not configured for migration' do
    let(:terraform_backend_configuration) {
      {
        'bucket' => 'dummy_bucket_name',
        'migrate' => false
      }
    } 

    it 'does use remote state' do
      expect(stack_instance.backend_configuration.remote_state?).to be true
    end

    it 'will not migrate state' do
      expect(stack_instance.backend_configuration.migrate_state?).to be false
    end
  end


  describe 'configured for migration' do

    let(:terraform_backend_configuration) {
      {
        'bucket' => 'dummy_bucket_name',
        'migrate' => 'TRUE'
      }
    }

    it 'knows we want to migrate the state' do
      expect(stack_instance.backend_configuration.migrate_state?).to be true
    end

    it 'adds a backend configuration file' do
      working_copy_folder = stack_instance.prepare
      expect(File).to exist("#{working_copy_folder}/_cloudspin_backend.tf")
    end
  end

end
