# encoding: UTF-8

module Delayed
  module JobGroups
    module JobExtensions
      extend ActiveSupport::Concern

      included do
        if Delayed::JobGroups::Compatibility.mass_assignment_security_enabled?
          attr_accessible :job_group_id, :blocked
        end

        belongs_to :job_group, class_name: 'Delayed::JobGroups::JobGroup'

        class << self

          # Patch ready_to_run to exclude blocked jobs
          def ready_to_run_with_blocked_filtering(worker_name, max_run_time)
            ready_to_run_without_blocked_filtering(worker_name, max_run_time).where(blocked: false)
          end
          alias_method_chain :ready_to_run, :blocked_filtering
        end
      end

      def in_job_group?
        job_group_id.present?
      end
    end
  end
end
