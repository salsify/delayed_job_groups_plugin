# frozen_string_literal: true

Delayed::Backend::ActiveRecord::Job.include Delayed::JobGroups::JobExtensions
