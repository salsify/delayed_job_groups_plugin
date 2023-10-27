# frozen_string_literal: true

require 'active_support/version'
require 'active_record/version'

module Delayed
  module JobGroups
    module Compatibility
      ACTIVE_RECORD_VERSION = ::Gem::Version.new(::ActiveRecord::VERSION::STRING).release
      VERSION_7_1 = ::Gem::Version.new('7.1.0')

      def self.rails_7_1_or_greater?
        ACTIVE_RECORD_VERSION >= VERSION_7_1
      end
    end
  end
end
