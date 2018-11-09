RSpec.describe 'Stack::InstanceConfiguration' do

  # SMELL: We shouldn't need to have a physical state folder if we don't have an instance
  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }

  let(:stack_definition) { 
    Cloudspin::Stack::Definition.new(
      source_path: '/some/path',
      stack_name: 'a_name'
    )
  }

  let(:configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(
      configuration_values: instance_configuration_values,
      stack_definition: stack_definition,
      base_folder: base_folder
    )
  }

  let(:instance_configuration_values) {{}} 

  describe 'with no instance configuration' do
    it 'sets a local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to_not be_empty
    end

    it 'sets the expected local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to match /\/state\/a_name$/
    end

  end

  describe 'with terraform backend configured' do
    let(:terraform_config) {
      {
        'terraform_backend' => { 'bucket' => 'the_bucket' }
      }
    }
    let(:configuration) {
      Cloudspin::Stack::InstanceConfiguration.new(
        configuration_values: terraform_config,
        stack_definition: stack_definition,
        base_folder: base_folder
      )
    }

    it 'does not set a local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to be_nil
    end

    it 'sets the bucket' do
      expect(configuration.terraform_backend['bucket']).to eq('the_bucket')
    end

    it 'sets the key' do
      expect(configuration.terraform_backend['key']).to eq('a_name.tfstate')
    end

  end

  describe 'with a backend region configured' do
    let(:instance_configuration_values) {
      {
        'terraform_backend' => {
          'region' => 'lu-tyco-1'
        }
      }
    }

    it 'does not set a local state folder' do
      expect(configuration.terraform_backend['statefile_folder']).to be_nil
    end

  end

end
