# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module DelayedJobGroupsPlugin
  class AddFailedAtToDelayedJobGroupsGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template('add_failed_at_to_delayed_job_groups.erb', 'db/migrate/add_failed_at_to_delayed_job_groups.rb')
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

  end
end
