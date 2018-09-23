
RSpec.describe 'Stack::Instance' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'my_stack')
  }

  describe 'created from code' do

    let(:source_path) { '/does/not/matter' }
    let(:working_folder) { '/does/not/matter/work' }
    let(:statefile_folder) { '/tmp/state' }

    let(:stack_instance) {
      Cloudspin::Stack::Instance.new(
        id: 'test_stack_instance',
        stack_definition: stack_definition,
        working_folder: working_folder,
        configuration: instance_configuration
      )
    }

    let(:instance_configuration) {
      Cloudspin::Stack::InstanceConfiguration.new(stack_definition, '.')
    }

    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('test_stack_instance')
    end
  end

  describe 'created from files' do
    let(:working_folder) { Dir.mktmpdir(['', '-work']) }
    let(:base_folder) { Dir.mktmpdir(['cloudspin-']) }

    let(:source_path) {
      src = Dir.mktmpdir
      File.write("#{src}/main.tf", '# Empty terraform file')
      src
    }

    let(:first_config_file) {
      tmp = Tempfile.new('first_instance_config.yaml')
      tmp.write(<<~FIRST_YAML_FILE
        ---
        parameters:
          x: 6
        resources:
          a: 1
        FIRST_YAML_FILE
      )
      tmp.close
      tmp.path
    }

    let(:second_config_file) {
      tmp = Tempfile.new('second_instance_config.yaml')
      tmp.write(<<~SECOND_YAML_FILE
        ---
        parameters:
          x: 9
          y: 8
        resources:
          b: 2
        SECOND_YAML_FILE
      )
      tmp.close
      tmp.path
    }

    let(:stack_instance) {
      Cloudspin::Stack::Instance.from_files(
        first_config_file,
        second_config_file,
        stack_definition: stack_definition,
        base_folder: base_folder,
        base_working_folder: working_folder,
      )
    }

    it 'has the expected stack_identifier' do
      expect(stack_instance.id).to eq('my_stack')
    end

    it 'adds the instance_identifier to the terraform variables' do
      expect(stack_instance.terraform_variables).to include('instance_identifier' => 'my_stack')
    end

    it 'will use an instance-specific working folder' do
      expect(stack_instance.working_folder).to match(/-work\/my_stack$/)
    end

    it 'is planned without error' do
      expect { stack_instance.plan }.not_to raise_error
    end

    it 'returns a reasonable-looking plan command' do
      expect( stack_instance.plan_dry ).to match(/terraform plan/)
    end

    it 'includes the instance parameters in the terraform command' do
      expect( stack_instance.plan_dry ).to match(/-var 'x=9'/)
      expect( stack_instance.plan_dry ).to match(/-var 'y=8'/)
    end

    it 'includes the required resources in the terraform command' do
      expect( stack_instance.plan_dry ).to match(/-var 'a=1'/)
      expect( stack_instance.plan_dry ).to match(/-var 'b=2'/)
    end
  end

end
