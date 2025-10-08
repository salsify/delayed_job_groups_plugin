# frozen_string_literal: true

module Delayed
  module JobGroups
    ConfigurationError = Class.new(StandardError)

    class IncompatibleWithDelayedJobError < ConfigurationError
      DEFAULT_MESSAGE = 'DelayedJobGroupsPlugin is incompatible with Delayed::Job ' \
                        'when `destroy_failed_jobs` is set to `true`'

      def initialize(msg = DEFAULT_MESSAGE)
        super(msg)
      end
    end
  end
end
