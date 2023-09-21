# frozen_string_literal: true

module Delayed
  module JobGroups
    class CompleteStuckJobGroupsJob
      class << self
        def enqueue(**kwargs)
          Delayed::Job.enqueue(new, **kwargs)
        end
      end

      def perform
        Delayed::JobGroups::JobGroup.ready.with_no_open_jobs.find_each do |job_group|
          job_group.check_for_completion(skip_pending_jobs_check: true)
        end
      end
    end
  end
end
