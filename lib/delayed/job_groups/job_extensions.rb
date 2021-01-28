# frozen_string_literal: true

module Delayed
  module JobGroups
    module JobExtensions
      extend ActiveSupport::Concern
      module ReadyToRunExtension
        def ready_to_run(worker_name, max_run_time)
          super(worker_name, max_run_time).where(blocked: false)
        end
      end

      included do
        if Delayed::JobGroups::Compatibility.mass_assignment_security_enabled?
          attr_accessible :job_group_id, :blocked
        end

        belongs_to :job_group, class_name: 'Delayed::JobGroups::JobGroup', required: false

        class << self
          prepend ReadyToRunExtension
        end
      end
      def in_job_group?
        job_group_id.present?
      end
    end
  end
end
