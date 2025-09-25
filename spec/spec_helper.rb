# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
)

SimpleCov.start do
  add_filter 'spec'
end

require 'rspec/its'
require 'database_cleaner'
require 'delayed_job_groups_plugin'
require 'factory_bot'
require 'yaml'
require 'timecop'

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
db_config = YAML.safe_load(File.read('spec/db/database.yml'))
ActiveRecord::Base.establish_connection(db_config[db_adapter])
require 'db/schema'

RSpec.configure do |config|
  config.order = 'random'

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.find_definitions
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.include FactoryBot::Syntax::Methods
end
