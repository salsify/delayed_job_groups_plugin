# encoding: UTF-8

require 'delayed_job'
require 'set'

module Delayed
  module JobGroups
    class Plugin < Delayed::Plugin

      # Delayed job callbacks will be registered in a global Delayed::Lifecycle every time a
      # Delayed::Worker is created. This creates problems in test runs that create
      # multiple workers because we register the callbacks multiple times on the same
      # global Lifecycle.
      def self.callbacks(&block)
        registered_lifecycles = Set.new
        super do |lifecycle|
          if registered_lifecycles.add?(lifecycle.object_id)
            block.call(lifecycle)
          end
        end
      end

      callbacks do |lifecycle|
        lifecycle.before(:error) do |worker, job|
          # If the job group has been cancelled then don't let the job be retried
          if job.in_job_group? && job_group_cancelled?(job.job_group_id)
            def job.max_attempts
              1
            end
          end
        end

        lifecycle.before(:failure) do |worker, job|
          # If a job in the job group fails, then cancel the whole job group.
          # Need to check that the job group is present since another
          # job may have concurrently cancelled it.
          if job.in_job_group? && job.job_group && job.job_group.failure_cancels_group?
            job.job_group.cancel
          end
        end

        lifecycle.after(:perform) do |worker, job|
          # Make sure we only check to see if the job group is complete
          # if the job succeeded
          if job.in_job_group? && job_completed?(job)
            JobGroup.check_for_completion(job.job_group_id)
          end
        end
      end

      private

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

