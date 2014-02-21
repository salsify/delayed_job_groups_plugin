source 'https://rubygems.org'

gem 'rake'

group :test do
  gem 'activerecord', ENV.fetch('RAILS_VERSION', ['>= 3.2', '< 4.1'])
  gem 'coveralls', require: false
  gem 'database_cleaner', '>= 1.2'
  gem 'delayed_job', '>= 3.0'
  gem 'delayed_job_active_record', '>= 0.4'
  gem 'rspec', '>= 2.14'
  # See https://github.com/colszowka/simplecov/issues/281 for why we need 0.7.1
  gem 'simplecov', '~> 0.7.1', require: false

  platforms :ruby do
    gem 'sqlite3'
  end

  platforms :jruby do
    gem 'activerecord-jdbcsqlite3-adapter'
    gem 'jdbc-sqlite3'
  end
end

gemspec
