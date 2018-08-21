require 'cloudspin/cli'

RSpec.describe Cloudspin::CLI do

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  describe 'info' do
    it 'should print the configuration file list' do
      expect(capture(:stdout) { subject.info }).to match(/^Configuration file:/)
    end
  end

  # describe 'up' do
  #   it 'should print the command with --dry' do
  #     subject.options = {:dry => true}
  #     expect(capture(:stdout) { subject.up }).to match(/^terraformX/)
  #   end
  # end

end

