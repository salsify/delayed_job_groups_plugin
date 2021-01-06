# frozen_string_literal: true

module Delayed
  module JobGroups
    class Railtie < ::Rails::Railtie
      config.after_initialize do
        Delayed::Backend::ActiveRecord::Job.include(Delayed::JobGroups::JobExtensions)
      end
    end
  end
end
