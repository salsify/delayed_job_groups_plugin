# frozen_string_literal: true

require 'active_support'
require 'active_record'
require 'delayed_job'
require 'delayed_job_active_record'
require 'delayed/job_groups/configuration'
require 'delayed/job_groups/compatibility'
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
end

Delayed::Worker.plugins << Delayed::JobGroups::Plugin

module Delayed
  module JobGroups
    @configuration = Delayed::JobGroups::Configuration.new

    class << self
      def configure
        yield(configuration) if block_given?
      end

      def configuration
        @configuration
      end
    end
  end
end
