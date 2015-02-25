# encoding: UTF-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'delayed/job_groups/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_job_groups_plugin'
  spec.version       = Delayed::JobGroups::VERSION
  spec.authors       = ['Joel Turkel']
  spec.email         = ['jturkel@salsify.com']
  spec.description   = %q{Aggregates Delayed::Job jobs into groups with group level management and lifecycle callbacks}
  spec.summary       = %q{Delayed::Job job groups plugin}
  spec.homepage      = 'https://github.com/salsify/delayed_job_groups_plugin'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = Dir.glob('spec/**/*')
  spec.require_paths = ['lib']

  spec.add_dependency 'delayed_job', '>= 3.0'
  spec.add_dependency 'delayed_job_active_record', '>= 0.4'

  spec.post_install_message = 'See https://github.com/salsify/delayed_job_groups_plugin#installation for upgrade/installation notes.'

  spec.add_development_dependency 'activerecord', ENV.fetch('RAILS_VERSION', ['>= 3.2', '< 4.1'])
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'database_cleaner', '>= 1.2'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 2.14', '< 2.99'
  spec.add_development_dependency 'simplecov', '~> 0.7.1'
  spec.add_development_dependency 'timecop'

  if RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'jdbc-sqlite3'
    spec.add_development_dependency 'activerecord-jdbcsqlite3-adapter'
  else
    spec.add_development_dependency 'sqlite3'
  end

end
