# frozen_string_literal: true

require 'delayed_job'
require 'set'

module Delayed
  module JobGroups
    class Configuration
      attr_accessor :error_reporter
    end
  end
end
