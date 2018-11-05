# frozen_string_literal: true

require 'active_support/version'
require 'active_record/version'

module Delayed
  module JobGroups
    module Compatibility

      def self.mass_assignment_security_enabled?
        defined?(::ActiveRecord::MassAssignmentSecurity)
      end

    end
  end
end
