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

    it 'includes the -state parameter for plan command' do
      expect(stack_instance.plan_dry).to match(/-state=/)
    end

    it 'passes the expected path for the local state to the plan command' do
      expect(stack_instance.plan_dry).to match(/-state=\S+\/state\/my_stack\/my_stack\.tfstate/)
    end

    it 'does not pass backend arguments to the init command' do
      expect(stack_instance.init_dry).to_not match(/\-backend/)
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

    it 'passes -backend argument to the init command' do
      expect(stack_instance.init_dry).to match(/\-backend/)
    end

    it 'passes a -backend-config argument to the init command' do
      expect(stack_instance.init_dry).to match(/\-backend-config/)
    end

    it 'does not pass the -state parameter to the plan command' do
      expect(stack_instance.plan_dry).to_not match(/-state=/)
    end

    it 'does not pass a -backend-config argument to the plan command' do
      expect(stack_instance.plan_dry).to_not match(/\-backend-config/)
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

    it 'passes -backend argument to the init command' do
      expect(stack_instance.init_dry).to match(/\-backend/)
    end
  end

end
