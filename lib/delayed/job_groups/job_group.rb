# frozen_string_literal: true

require_relative 'yaml_loader'

module Delayed
  module JobGroups
    class JobGroup < ActiveRecord::Base

      self.table_name = "#{ActiveRecord::Base.table_name_prefix}delayed_job_groups"

      serialize :on_completion_job, Delayed::JobGroups::YamlLoader
      serialize :on_completion_job_options, Hash
      serialize :on_cancellation_job, Delayed::JobGroups::YamlLoader
      serialize :on_cancellation_job_options, Hash

      validates :queueing_complete, :blocked, :failure_cancels_group, inclusion: [true, false]

      has_many :active_jobs, -> { where(failed_at: nil) }, class_name: '::Delayed::Job'

      # Only delete dependent jobs that are unlocked so we can determine if there are in-flight jobs
      # for canceled job groups
      has_many :queued_jobs, -> { where(failed_at: nil, locked_by: nil) }, class_name: '::Delayed::Job',
                dependent: :delete_all

      def mark_queueing_complete
        with_lock do
          raise 'JobGroup has already completed queueing' if queueing_complete?

          update_column(:queueing_complete, true)
          complete if ready_for_completion?
        end
      end

      def enqueue(job, options = {})
        options = options.merge(job_group_id: id)
        options[:blocked] = blocked?
        Delayed::Job.enqueue(job, options)
      end

      def unblock
        return unless blocked?

        with_lock do
          update_column(:blocked, false)
          active_jobs.update_all(blocked: false, run_at: Delayed::Job.db_time_now)
          complete if ready_for_completion?
        end
      end

      def cancel
        job = nil
        job_options = nil

        # Deserialization of the job or its options can fail
        begin
          job = on_cancellation_job
          job_options = on_cancellation_job_options
        rescue StandardError => e
          Delayed::Worker.logger.info('Failed to deserialize the on_cancellation_job or on_cancellation_job_options ' \
                                      "for job_group_id=#{id}. Skipping on_cancellation_job to clean up job group.")
          error_reporter.call(e) if error_reporter
        end

        Delayed::Job.enqueue(job, job_options || {}) if job

        destroy
      end

      def self.check_for_completion(job_group_id)
        # Optimization to avoid loading and locking the JobGroup when the group
        # still has pending jobs
        return if has_pending_jobs?(job_group_id)

        transaction do
          # The first completed job to notice the job group's queue count has dropped to
          # zero will queue the job group's completion job and destroy the job group so
          # other jobs need to handle the job group having been destroyed already.
          job_group = where(id: job_group_id).lock(true).first
          job_group.send(:complete) if job_group&.send(:ready_for_completion?)
        end
      end

      def self.has_pending_jobs?(job_group_ids) # rubocop:disable Naming/PredicateName
        job_group_ids = Array(job_group_ids)
        return false if job_group_ids.empty?

        Delayed::Job.where(job_group_id: job_group_ids, failed_at: nil).exists?
      end

      private

      def ready_for_completion?
        queueing_complete? && !JobGroup.has_pending_jobs?(id) && !blocked?
      end

      def complete
        job = nil
        job_options = nil

        # Deserialization of the job or its options can fail
        begin
          job = on_completion_job
          job_options = on_completion_job_options
        rescue StandardError => e
          Delayed::Worker.logger.info('Failed to deserialize the on_completion_job or on_completion_job_options for ' \
                                      "job_group_id=#{id}. Skipping on_completion_job to clean up job group.")
          error_reporter.call(e) if error_reporter
        end

        Delayed::Job.enqueue(job, job_options || {}) if job
        destroy
      end

      def error_reporter
        Delayed::JobGroups.configuration.error_reporter
      end
    end
  end
end
