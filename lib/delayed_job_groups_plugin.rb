# frozen_string_literal: true

require 'active_support'
require 'active_record'
require 'delayed_job'
require 'delayed_job_active_record'
require 'delayed/job_groups/errors'
require 'delayed/job_groups/compatibility'
require 'delayed/job_groups/complete_stuck_job_groups_job'
require 'delayed/job_groups/job_extensions'
require 'delayed/job_groups/job_group'
require 'delayed/job_groups/plugin'
require 'delayed/job_groups/yaml_loader'
require 'delayed/job_groups/version'

if defined?(Rails::Railtie)
  # Postpone initialization to railtie for correct order
  require 'delayed/job_groups/railtie'
else
  # Do the same as in the railtie
  Delayed::Backend::ActiveRecord::Job.include(Delayed::JobGroups::JobExtensions)
  raise Delayed::JobGroups::IncompatibleWithDelayedJobError if Delayed::Worker.destroy_failed_jobs
end

Delayed::Worker.plugins << Delayed::JobGroups::Plugin
