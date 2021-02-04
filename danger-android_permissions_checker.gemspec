# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'android_permissions_checker/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'danger-android_permissions_checker'
  spec.version       = AndroidPermissionsChecker::VERSION
  spec.authors       = ['mataku']
  spec.email         = ['sfprhythnn@gmail.com']
  spec.description   = %q{A Danger plugin to check diff of android apk permissions.}
  spec.summary       = %q{A Danger plugin to check diff of android apk permissions.}
  spec.homepage      = 'https://github.com/mataku/danger-android_permissions_checker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'danger-plugin-api', '~> 1.0'

  # General ruby development
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  # Testing support
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
end
