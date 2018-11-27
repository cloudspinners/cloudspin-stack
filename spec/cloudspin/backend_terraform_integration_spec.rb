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
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }

  describe 'with no instance configuration' do
    it 'does not use remote state' do
      expect(backend_configuration.remote_state?).to be false
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

  describe 'with remote backend configuration migrate=true' do
    let(:terraform_backend_configuration_values) {
      {
        'bucket' => 'dummy_bucket_name',
        'migrate' => 'TRUE'
      }
    } 

    it 'does use remote state' do
      expect(backend_configuration.remote_state?).to be true
    end

    it 'will try to migrate state' do
      expect(backend_configuration.migrate_state?).to be true
    end

    it 'has the local state path to migrate' do
      expect(backend_configuration.local_state_folder).to match /\/state\/dummy_instance$/
    end
  end

  describe 'with remote backend configuration migrate=false' do
    let(:terraform_backend_configuration_values) {
      {
        'bucket' => 'dummy_bucket_name',
        'migrate' => false
      }
    } 

    it 'does use remote state' do
      expect(backend_configuration.remote_state?).to be true
    end

    it 'will not migrate state' do
      expect(backend_configuration.migrate_state?).to be false
    end
  end

  # describe 'with terraform backend configured' do
  #   let(:terraform_config) {
  #     {
  #       'terraform_backend' => { 'bucket' => 'the_bucket' }
  #     }
  #   }
  #   let(:configuration) {
  #     Cloudspin::Stack::InstanceConfiguration.new(
  #       configuration_values: terraform_config,
  #       stack_definition: stack_definition,
  #       base_folder: base_folder
  #     )
  #   }

  #   it 'does set a local state folder' do
  #     expect(backend_configuration.statefile_folder).not_to be_nil
  #   end
  #   # it 'does not set a local state folder' do
  #   #   expect(backend_configuration.statefile_folder).to be_nil
  #   # end

  #   it 'sets the bucket' do
  #     expect(backend_configuration.bucket).to eq('the_bucket')
  #   end

  #   it 'sets the key' do
  #     expect(backend_configuration.key).to eq('a_name.tfstate')
  #   end

  # end

  # describe 'with a backend region configured' do
  #   let(:instance_configuration_values) {
  #     {
  #       'terraform_backend' => {
  #         'region' => 'lu-tyco-1'
  #       }
  #     }
  #   }

  #   # it 'does not set a local state folder' do
  #   #   expect(backend_configuration.statefile_folder).to be_nil
  #   # end
  #   it 'does set a local state folder' do
  #     expect(backend_configuration.statefile_folder).not_to be_nil
  #   end

  # end

end
