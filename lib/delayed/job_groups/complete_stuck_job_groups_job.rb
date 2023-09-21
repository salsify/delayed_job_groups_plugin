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
        Delayed::JobGroups::JobGroup.ready.find_each(&:check_for_completion)
      end
    end
  end
end
