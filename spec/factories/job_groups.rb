# frozen_string_literal: true

FactoryBot.define do
  factory :job_group, class: 'Delayed::JobGroups::JobGroup' do
    blocked { false }
    queueing_complete { false }
    on_completion_job { nil }
    on_completion_job_options { nil }
  end
end
