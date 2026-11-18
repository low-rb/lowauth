# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'lowauth'
  spec.version = LowAuth::VERSION
  spec.authors = ['maedi']
  spec.email = ['maediprichard@gmail.com']

  spec.summary = 'Logins for Raindeer'
  spec.description = 'Passwords, sessions and guards on nodes, for Raindeer and LowNode'
  spec.homepage = 'https://github.com/low-rb/lowauth'
  spec.license = 'MPL-2.0'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('lib/**/*')
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'argon2', '~> 2.3'
  spec.add_dependency 'lownode', '~> 0.5', '>= 0.5.8'
  spec.add_dependency 'sequel', '~> 5.0'
end
