RSpec.describe 'Stack::InstanceConfiguration' do

  let(:backend_configuration) {
    Cloudspin::Stack::BackendConfiguration.new(
      terraform_backend_configuration_values: terraform_backend_configuration_values,
      instance_identifier: 'dummy_instance',
      stack_name: 'dummy_stack',
      base_folder: base_folder
    )
  }

  let(:terraform_backend_configuration_values) {{}} 

  let(:base_folder) {
    Dir.mktmpdir(['cloudspin-'])
  }

  describe 'with no instance configuration' do
    it 'does not use remote state' do
      expect(backend_configuration.remote_state?).to be false
    end

    it 'uses local state' do
      expect(backend_configuration.local_state?).to be true
    end

    it 'sets a local state folder' do
      expect(backend_configuration.local_state_folder).to_not be_empty
    end

    it 'sets the expected local state folder' do
      expect(backend_configuration.local_state_folder).to match /\/state\/dummy_instance$/
    end

    it 'will not migrate state' do
      expect(backend_configuration.migrate_state?).to be false
    end

    it 'sets the necessary terraform init parameters' do
      expect(backend_configuration.terraform_init_parameters).to eq({})
    end

    it 'sets the necessary terraform command parameters' do
      expect(backend_configuration.terraform_command_parameters[:state]).to match /\/state\/dummy_instance\/dummy_instance\.tfstate$/
    end
  end

  describe 'with remote backend configured' do
    let(:terraform_backend_configuration_values) {
      {
        'bucket' => 'dummy_bucket_name',
        'region' => 'dummy_bucket_region'
      }
    } 

    it 'does use remote state' do
      expect(backend_configuration.remote_state?).to be true
    end

    it 'will not migrate state' do
      expect(backend_configuration.migrate_state?).to be false
    end

    it 'sets the necessary terraform init parameters' do
      expect(backend_configuration.terraform_init_parameters[:backend]).to eq 'true'
    end

    it 'does not include the -state argument for terraform init' do
      expect(backend_configuration.terraform_init_parameters[:state]).to be_nil
    end

    it 'sets the necessary terraform command parameters' do
      expect(backend_configuration.terraform_command_parameters).to eq({})
    end
  end

  describe 'with remote backend and local statefile' do

    let!(:statefile) do
      mkdir_p "#{base_folder}/state/dummy_instance"
      touch "#{base_folder}/state/dummy_instance/dummy_instance.tfstate"
    end

    let(:terraform_backend_configuration_values) {
      {
        'bucket' => 'dummy_bucket_name',
        'region' => 'dummy_bucket_region'
      }
    }

    it 'knows we want to migrate the state' do
      expect(backend_configuration.migrate_state?).to be true
    end

    it 'plans to use remote state' do
      expect(backend_configuration.remote_state?).to be true
    end

    it 'plans to use local state' do
      expect(backend_configuration.local_state?).to be true
    end

    it 'has the path to the local state folder' do
      expect(backend_configuration.local_state_folder).to match /\/state\/dummy_instance$/
    end
  end

end
