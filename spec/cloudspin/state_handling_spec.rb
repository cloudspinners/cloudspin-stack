RSpec.describe 'Stack::Instance' do

  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }
  let(:source_path) { '/does/not/matter/src' }
  let(:working_folder) { "#{base_folder}/work" }
  let(:statefile_folder) { Dir.mktmpdir(['cloudspin-', '-state']) }

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path,
                                     stack_name: 'my_stack')
  }

  let(:instance_configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(
      configuration_values: configuration_values,
      stack_definition: stack_definition,
      base_folder: base_folder
    )
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      id: 'test_stack_instance',
      stack_definition: stack_definition,
      working_folder: working_folder,
      configuration: instance_configuration
    )
  }

  describe 'without an explicit state configuration' do
    let(:configuration_values) {{}}

    it 'includes the -state parameter in the terraform arguments' do
      expect(stack_instance.terraform_command_arguments[:state]).to_not be_nil
    end

    it 'knows the expected path for the local terraform state' do
      expect(stack_instance.terraform_command_arguments[:state]).to match(/\/state\/my_stack\/my_stack\.tfstate/)
    end

    it 'will not include the -state argument for the init command' do
      expect(stack_instance.terraform_init_arguments[:state]).to be_nil
    end
  end


  describe 'with remote state configuration' do
    let(:configuration_values) {
      {
        'terraform_backend' => {
          'bucket' => 'dummy_bucket_name',
          'region' => 'dummy_bucket_region'
        }
      }
    }

    it 'has a backend configuration with remote enabled' do
      expect(instance_configuration.backend_configuration.remote_state?).to be true
    end

    it 'knows it should use a remote backend' do
      expect(instance_configuration.has_remote_state_configuration?).to be true
    end

    it 'includes the -backend argument for the init command' do
      expect(stack_instance.terraform_init_arguments[:backend]).to_not be_nil
    end

    it 'includes the -backend-config argument for the init command' do
      expect(stack_instance.terraform_init_arguments[:backend_config]).to_not be_nil
    end

    it 'does not include the -state parameter for terraform commands' do
      expect(stack_instance.terraform_command_arguments[:state]).to be_nil
    end

    it 'does not include the -backend-config parameter for terraform commands other than init' do
      expect(stack_instance.terraform_command_arguments[:backend_config]).to be_nil
    end

  end


  describe 'configured to migrate to backend' do
    let(:configuration_values) {
      {
        'terraform_backend' => {
          'bucket' => 'dummy_bucket_name',
          'region' => 'dummy_bucket_region',
          'migrate' => 'TRUE'
        }
      }
    }

    it 'will use the -backend argument for the terraform init command' do
      expect(stack_instance.terraform_init_arguments[:backend]).to_not be_nil
    end
  end

end
