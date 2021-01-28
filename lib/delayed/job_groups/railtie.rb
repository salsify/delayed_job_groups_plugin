# frozen_string_literal: true

module Delayed
  module JobGroups
    class Railtie < Rails::Railtie
      config.after_initialize do
        require 'delayed/job_groups/patch'
      end
    end
  end
end
