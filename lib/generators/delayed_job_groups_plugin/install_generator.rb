# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module DelayedJobGroupsPlugin
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template('migration.erb', 'db/migrate/create_delayed_job_groups.rb')
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def create_initializer
      initializer_file = File.join('config/initializers', 'delayed_job_config.rb')
      configuration_on_matcher = /Delayed::Worker\.destroy_failed_jobs\s*=\s*true/
      configuration_off_matcher = /Delayed::Worker\.destroy_failed_jobs\s*=\s*false/

      say 'Attempting to initialize delayed_job_config initializer...', :green

      if File.exist?(initializer_file)
        say 'delayed_job_config initializer already exists... checking destroy_failed_jobs options', :green
        contents = File.read(initializer_file)
        if contents.match(configuration_on_matcher)
          say 'Delayed::Worker.destroy_failed_jobs is set to true', :red
          say 'This library requires the option to be set to false, updating config now!', :yellow

          gsub_file initializer_file, configuration_on_matcher, 'Delayed::Worker.destroy_failed_jobs = false'
        elsif contents.match(configuration_off_matcher)
          say 'Delayed::Worker.destroy_failed_jobs is set to false; nothing to do!', :green
        else
          say 'Delayed::Worker.destroy_failed_jobs is not set'
          say 'This library requires the option to be set to false, updating config now!', :yellow
          inject_into_file initializer_file, "Delayed::Worker.destroy_failed_jobs = false\n"
        end
      else
        create_file initializer_file do
          <<~RUBY
            # frozen_string_literal: true

            Delayed::Worker.destroy_failed_jobs = false
          RUBY
        end
      end
    end
  end
end
