# frozen_string_literal: true

require 'delayed_job'
require 'set'

module Delayed
  module JobGroups
    class Plugin < Delayed::Plugin

      callbacks do |lifecycle|
        lifecycle.before(:error) do |_worker, job|
          # If the job group has been cancelled then don't let the job be retried
          if job.in_job_group? && job_group_cancelled?(job.job_group_id)
            def job.max_attempts
              1
            end
          end
        end

        lifecycle.before(:failure) do |_worker, job|
          # If a job in the job group fails, then cancel the whole job group.
          # Need to check that the job group is present since another
          # job may have concurrently cancelled it.
          if job.in_job_group? && job.job_group && job.job_group.failure_cancels_group?
            job.job_group.cancel
          end
        end

        lifecycle.after(:perform) do |_worker, job|
          # Make sure we only check to see if the job group is complete
          # if the job succeeded
          if job.in_job_group? && job_completed?(job)
            JobGroup.check_for_completion(job.job_group_id)
          end
        end
      end

      def self.job_group_cancelled?(job_group_id)
        !JobGroup.exists?(job_group_id)
      end

      def self.job_completed?(job)
        # Delayed job will already have marked the job for destruction
        # if it has completed
        job.destroyed?
      end
    end
  end
end
