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

  let(:stack_instance) {
    Cloudspin::Stack::Instance.new(
      id: 'test_stack_instance',
      stack_definition: stack_definition,
      working_folder: working_folder,
      configuration: instance_configuration
    )
  }

  describe 'without an explicit state configuration' do
    let(:instance_configuration) {
      Cloudspin::Stack::InstanceConfiguration.new(
        stack_definition: stack_definition,
        base_folder: base_folder
      )
    }

    it 'includes the -state parameter on the commandline' do
      expect(stack_instance.plan_dry).to match(/-state=/)
    end

    it 'passes the expected path for the local state' do
      expect(stack_instance.plan_dry).to match(/-state=\S+\/state\/my_stack\/my_stack\.tfstate/)
    end

    it 'does not pass backend arguments to the init command' do
      expect(stack_instance.init_dry).to_not match(/\-backend/)
    end
  end

end
