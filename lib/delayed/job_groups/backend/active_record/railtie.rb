module Delayed
  module JobGroups
    module Backend
      module ActiveRecord
        class Railtie < ::Rails::Railtie
          config.after_initialize do
            Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::JobGroups::JobExtensions)
          end
        end
      end
    end
  end
end