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

  let(:instance_configuration_values) {{}}

  describe 'minimal instance' do
    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('test_stack_instance')
    end

    it 'defines a working folder for the instance' do
      expect(stack_instance.working_folder).to eq("#{working_folder}/#{stack_instance.id}")
    end
  end

  describe 'preparing the instance' do
    it 'creates the working folder' do
      stack_instance.prepare
      expect(File).to be_directory("#{working_folder}/#{stack_instance.id}")
    end

    it 'copies the source to the working folder' do
      working_copy_folder = stack_instance.prepare
      expect(File.exists?("#{working_copy_folder}/main.tf")).to be(true)
    end

    it 'generates a .tfvars file' do
      working_copy_folder = stack_instance.prepare
      expect(File.exists?("#{working_copy_folder}/_cloudspin-test_stack_instance.auto.tfvars")).to be(true)
    end
  end

  describe 'with local backend' do
    it 'configures a local state folder' do
      expect(stack_instance.backend_configuration.local_state_folder).to_not be_empty
    end

    it 'creates a local state folder' do
      working_copy_folder = stack_instance.prepare
      expect(File).to be_directory(stack_instance.backend_configuration.local_state_folder)
    end

    it 'does not add a backend configuration file' do
      working_copy_folder = stack_instance.prepare
      expect(File).not_to exist("#{working_copy_folder}/_cloudspin_backend.tf")
    end
  end

  describe 'with remote backend' do
    let(:instance_configuration_values) {
      {
        'terraform_backend' => {
          'bucket' => 'something'
        }
      }
    }

    it 'does not configures a local state folder' do
      expect(stack_instance.backend_configuration.local_state_folder).to be_nil
    end

    it 'adds a backend configuration file' do
      working_copy_folder = stack_instance.prepare
      expect(File).to exist("#{working_copy_folder}/_cloudspin_backend.tf")
    end
  end

  describe 'terraform variable formatting' do
    it 'handles boolean true correctly' do
      expect(stack_instance.format_tfvar(true)).to eq('true')
    end

    it 'handles boolean false correctly' do
      expect(stack_instance.format_tfvar(false)).to eq('false')
    end

    it 'puts quotes on a string' do
      expect(stack_instance.format_tfvar("some string")).to eq('"some string"')
    end

    it 'puts quotes on a string with commas' do
      expect(stack_instance.format_tfvar("some,other,strings")).to eq('"some,other,strings"')
    end

    it 'outputs a list of strings with quotes around each' do
      expect(stack_instance.format_tfvar(['a','b'])).to eq('["a", "b"]')
    end

    it 'handles a list with mixed boolean and string' do
      expect(stack_instance.format_tfvar([false,'b'])).to eq('[false, "b"]')
    end

    it 'handles hashes correctly' do
      expect(stack_instance.format_tfvar({
        'key1' => 'value1',
        'key2' => true
      })).to eq('{ "key1": "value1", "key2": true }')
    end

  end

end
