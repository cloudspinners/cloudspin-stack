
RSpec.describe 'Stack::Instance' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: '/dev/null/src', stack_name: 'my_stack')
  }

  let(:instance_configuration) {
    Cloudspin::Stack::InstanceConfiguration.new(stack_definition)
  }

  let(:stack_instance_one) {
    Cloudspin::Stack::Instance.new(
      id: 'stack_one',
      stack_definition: stack_definition,
      statefile_folder: '/dev/null/state/stack_one',
      working_folder: '/dev/null/work/stack_one',
      configuration: instance_configuration
    )
  }

  let(:stack_instance_two) {
    Cloudspin::Stack::Instance.new(
      id: 'stack_two',
      stack_definition: stack_definition,
      statefile_folder: '/dev/null/state/stack_two',
      working_folder: '/dev/null/work/stack_two',
      configuration: instance_configuration
    )
  }

  describe 'two instances' do
    it 'do not clash' do
      expect(stack_instance_one.id).to eq('stack_one')
      expect(stack_instance_two.id).to eq('stack_two')
    end

  end

end
