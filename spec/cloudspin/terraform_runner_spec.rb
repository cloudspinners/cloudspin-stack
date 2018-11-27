RSpec.describe 'Cloudspin::Stack::Terraform' do

  let(:terraform_runner) {
    Cloudspin::Stack::Terraform.new(
      working_folder: working_folder,
      terraform_variables: {},
      terraform_init_arguments: {}
    )
  }

  let(:working_folder) {
    tmp_folder = Dir.mktmpdir(['cloudspin-', '-work'])
    File.write("#{tmp_folder}/main.tf", '# Empty terraform file')
    tmp_folder
  }

  describe 'terraform runner' do
    it 'is planned without error' do
      expect { terraform_runner.plan }.not_to raise_error
    end

    it 'returns a reasonable-looking plan command' do
      expect( terraform_runner.plan_dry ).to match(/terraform plan/)
    end
  end

end
