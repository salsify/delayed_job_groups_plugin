# frozen_string_literal: true

require_relative 'yaml_loader'
require_relative 'compatibility'

module Delayed
  module JobGroups
    class JobGroup < ActiveRecord::Base

      self.table_name = "#{ActiveRecord::Base.table_name_prefix}delayed_job_groups"

      if Compatibility.rails_7_1_or_greater?
        serialize :on_completion_job, coder: YAML, yaml: { unsafe_load: true }
        serialize :on_completion_job_options, coder: YAML, type: Hash
        serialize :on_cancellation_job, coder: YAML, yaml: { unsafe_load: true }
        serialize :on_cancellation_job_options, coder: YAML, type: Hash
      else
        serialize :on_completion_job, Delayed::JobGroups::YamlLoader
        serialize :on_completion_job_options, Hash
        serialize :on_cancellation_job, Delayed::JobGroups::YamlLoader
        serialize :on_cancellation_job_options, Hash
      end


      validates :queueing_complete, :blocked, :failure_cancels_group, inclusion: [true, false]

      has_many :active_jobs, -> { where(failed_at: nil) }, class_name: '::Delayed::Job'

      # Only delete dependent jobs that are unlocked so we can determine if there are in-flight jobs
      # for canceled job groups
      has_many :queued_jobs, -> { where(failed_at: nil, locked_by: nil) }, class_name: '::Delayed::Job',
                dependent: :delete_all

      scope :ready, -> { where(queueing_complete: true, blocked: false) }
      scope :with_no_open_jobs, -> do
        where("NOT EXISTS (#{Delayed::Job.where('delayed_jobs.job_group_id = delayed_job_groups.id').to_sql})")
      end

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
        with_lock do
          Delayed::Job.enqueue(on_cancellation_job, on_cancellation_job_options || {}) if on_cancellation_job
          destroy
        end
      rescue ActiveRecord::RecordNotFound
        # The first failing job to attempt cancelling the job group will enqueue the
        # on cancellation job and destroy the group. Any other concurrently failing job
        # in the same group can therefore silently return if the job group has already
        # been destroyed.
        nil
      end

      def check_for_completion(skip_pending_jobs_check: false)
        self.class.check_for_completion(id, skip_pending_jobs_check: skip_pending_jobs_check)
      end

      def self.check_for_completion(job_group_id, skip_pending_jobs_check: false)
        # Optimization to avoid loading and locking the JobGroup when the group
        # still has pending jobs
        return if !skip_pending_jobs_check && has_pending_jobs?(job_group_id)

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
        Delayed::Job.enqueue(on_completion_job, on_completion_job_options || {}) if on_completion_job
        destroy
      end
    end
  end
end
