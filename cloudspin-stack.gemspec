
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudspin/stack/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloudspin-stack'
  spec.version       = Cloudspin::Stack::VERSION
  spec.authors       = ['kief ']
  spec.email         = ['cloudspin@kief.com']

  spec.summary       = 'Classes to manage instances of an infrastructure stack using Terraform'
  spec.homepage      = 'https://github.com/cloudspinners'
  spec.license = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4.3'

  spec.add_dependency 'ruby-terraform'
  spec.add_dependency 'thor'
  spec.add_dependency 'rubyzip'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
end
