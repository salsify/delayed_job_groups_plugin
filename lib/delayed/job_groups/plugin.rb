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
          job.job_group.cancel if job.in_job_group? && job.job_group&.failure_cancels_group?
        end

        lifecycle.after(:perform) do |_worker, job|
          # Make sure we only check to see if the job group is complete
          # if the job succeeded or the job has failed (maxed out retries) with failure_cancels_group
          # set to false
          if job.in_job_group? && (job_completed?(job) || job_acceptably_failed?(job))
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

      def self.job_acceptably_failed?(job)
        # Job has set failed_at (retries have maxed out) and failure_cancels_group is false signaling
        # that the group should complete despite failures.
        job.failed_at.present? && job.job_group.present? && !job.job_group.failure_cancels_group?
      end
    end
  end
end
