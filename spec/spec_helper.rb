# encoding: UTF-8

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
 add_filter 'spec'
end

require 'database_cleaner'
require 'delayed_job_groups_plugin'
require 'yaml'

spec_dir = File.dirname(__FILE__)
Dir["#{spec_dir}/support/**/*.rb"].sort.each { |f| require f }

FileUtils.makedirs('log')

Delayed::Worker.read_ahead = 1
Delayed::Worker.destroy_failed_jobs = false

Delayed::Worker.logger = Logger.new('log/test.log')
Delayed::Worker.logger.level = Logger::DEBUG
ActiveRecord::Base.logger = Delayed::Worker.logger
ActiveRecord::Migration.verbose = false

db_adapter = ENV.fetch('ADAPTER', 'sqlite3')
config = YAML.load(File.read('spec/db/database.yml'))
ActiveRecord::Base.establish_connection(config[db_adapter])
require 'db/schema'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.order = 'random'

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
