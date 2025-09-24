# frozen_string_literal: true

module Delayed
  module JobGroups
    class Railtie < ::Rails::Railtie
      config.after_initialize do

        # On cancellation checks are performed in the after failure delayed job lifecycle, however
        # https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/worker.rb#L268 may
        # delete jobs before the hook runs. This could cause a successful job in the same group to
        # complete the group instead of the group being cancelled. Therefore, we must ensure that
        # the Delayed::Worker.destroy_failed_jobs is set to false, guaranteeing that the group is
        # never empty if failure occurs.
        raise Delayed::JobGroups::IncompatibleWithDelayedJobError if Delayed::Worker.destroy_failed_jobs

        Delayed::Backend::ActiveRecord::Job.include(Delayed::JobGroups::JobExtensions)
      end
    end
  end
end
