
RSpec.describe 'Cloudspin::Stack::Terraform' do

  let(:terraform_runner) {
    Cloudspin::Stack::Terraform.new(
      working_folder: stack_instance.working_folder,
      terraform_variables: stack_instance.terraform_variables,
      terraform_init_arguments: stack_instance.terraform_init_arguments
    )
  }

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      id: 'test_stack_instance',
      stack_definition: stack_definition,
      base_working_folder: base_working_folder,
      configuration: instance_configuration
    )
  }

  let(:instance_configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(
      configuration_values: configuration_values,
      stack_definition: stack_definition,
      base_folder: base_folder
    )
  }

  let(:configuration_values) {
    {
      'instance' => {
        'a' => '1',
        'b' => '2'
      },
      'parameters' => {
        'c' => '3',
        'd' => '4'
      },
      'resources' => {
        'e' => '5',
        'f' => '6'
      }
    }
  }

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'my_stack')
  }

  let(:base_working_folder) {
    FileUtils.mkdir_p "#{base_folder}/work"
    "#{base_folder}/work"
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


  describe 'given a stack instance' do

    it 'is planned without error' do
      expect {
        stack_instance.prepare
        terraform_runner.plan
      }.not_to raise_error
    end

    it 'returns a reasonable-looking plan command' do
      expect( terraform_runner.plan_dry ).to match(/terraform plan/)
    end

    it 'does not pass the terraform variables on the command line' do
      expect( terraform_runner.plan_dry ).to_not match(/-var/)
    end

  end

end
