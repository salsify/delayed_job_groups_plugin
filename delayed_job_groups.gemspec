
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed/job_groups/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_job_groups_plugin'
  spec.version       = Delayed::JobGroups::VERSION
  spec.authors       = ['Joel Turkel', 'Randy Burkes']
  spec.email         = ['jturkel@salsify.com', 'rlburkes@gmail.com']
  spec.description   = 'Aggregates Delayed::Job jobs into groups with group level management and lifecycle callbacks'
  spec.summary       = 'Delayed::Job job groups plugin'
  spec.homepage      = 'https://github.com/salsify/delayed_job_groups_plugin'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'delayed_job', '>= 4.1'
  spec.add_dependency 'delayed_job_active_record', '>= 4.1'

  spec.post_install_message = 'See https://github.com/salsify/delayed_job_groups_plugin#installation for upgrade/installation notes.'

  spec.add_development_dependency 'appraisal'
  spec.add_dependency 'activerecord', '>= 5.2', '< 7'
  spec.add_development_dependency 'coveralls_reborn', '>= 0.18.0'
  spec.add_development_dependency 'database_cleaner', '>= 1.2'
  spec.add_development_dependency 'mime-types'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'salsify_rubocop', '~> 1.0.1'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop'
end
