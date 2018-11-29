
RSpec.describe 'Stack::Instance' do

  let(:stack_definition) {
    Cloudspin::Stack::Definition.new(source_path: source_path, stack_name: 'my_stack')
  }

  let(:base_folder) {
    folder = Dir.mktmpdir(['cloudspin-'])
    FileUtils.mkdir_p "#{folder}/state"
    folder
  }

  describe 'created from files' do

    let(:working_folder) { Dir.mktmpdir(['', '-work']) }

    let(:source_path) {
      src = Dir.mktmpdir
      File.write("#{src}/main.tf", '# Empty terraform file')
      src
    }

    let(:first_config_file) {
      tmp = Tempfile.new('first_instance_config.yaml')
      tmp.write(<<~FIRST_YAML_FILE
        ---
        instance:
          me: you
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
        instance:
          this: that
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

    it 'has all the instance values from both files' do
      expect(stack_instance.configuration.instance_values['this']).to eq('that')
      expect(stack_instance.configuration.instance_values['me']).to eq('you')
    end

    it 'adds the instance_identifier to the terraform variables' do
      expect(stack_instance.terraform_variables).to include('instance_identifier' => 'my_stack')
    end

    it 'will use an instance-specific working folder' do
      expect(stack_instance.working_folder).to match(/-work\/my_stack$/)
    end
  end

end
