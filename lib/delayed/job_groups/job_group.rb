# encoding: UTF-8

module Delayed
  module JobGroups
    class JobGroup < ActiveRecord::Base

      self.table_name = "#{ActiveRecord::Base.table_name_prefix}delayed_job_groups"

      if Delayed::JobGroups::Compatibility.mass_assignment_security_enabled?
        attr_accessible :on_completion_job, :on_completion_job_options, :blocked, :on_cancellation_job,
                        :on_cancellation_job_options, :failure_cancels_group
      end

      serialize :on_completion_job
      serialize :on_completion_job_options, Hash
      serialize :on_cancellation_job
      serialize :on_cancellation_job_options, Hash

      validates :queueing_complete, :blocked, :failure_cancels_group, inclusion: [true, false]

      if ActiveRecord::VERSION::MAJOR >= 4
        has_many :active_jobs, -> { where(failed_at: nil) }, class_name: 'Job'
      else
        has_many :active_jobs, class_name: Job, conditions: {failed_at: nil}
      end


      # Only delete dependent jobs that are unlocked so we can determine if there are in-flight jobs
      # for canceled job groups
      if ActiveRecord::VERSION::MAJOR >= 4
        has_many :queued_jobs, -> { where(failed_at: nil, locked_by: nil) }, class_name: Job,
                 dependent: :delete_all
      else
        has_many :queued_jobs, class_name: Job, conditions: {failed_at: nil, locked_by: nil},
                 dependent: :delete_all
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
        Delayed::Job.enqueue(on_cancellation_job, on_cancellation_job_options || {}) if on_cancellation_job
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
          job_group.send(:complete) if job_group && job_group.send(:ready_for_completion?)
        end
      end

      def self.has_pending_jobs?(job_group_ids)
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
