# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed/job_groups/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_job_groups'
  spec.version       = Delayed::JobGroups::VERSION
  spec.authors       = ['Joel Turkel']
  spec.email         = ['jturkel@salsify.com']
  spec.description   = %q{Aggregates Delayed::Job jobs into groups with group level management and lifecycle callbacks}
  spec.summary       = %q{Delayed::Job job groups plugin}
  spec.homepage      = 'https://github.com/salsify/delayed_job_groups'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 2.14'
  spec.add_development_dependency 'activerecord', '>= 3.2'
  spec.add_development_dependency 'activesupport', '>= 3.2'
  spec.add_development_dependency 'delayed_job', '>= 3.0'
  spec.add_development_dependency 'delayed_job_active_record', '>= 0.4'
  spec.add_development_dependency 'database_cleaner', '>= 1.2'
  spec.add_development_dependency 'sqlite3', '>= 1.3'
end
