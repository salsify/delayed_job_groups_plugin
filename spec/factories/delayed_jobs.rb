# frozen_string_literal: true

FactoryBot.define do
  factory :delayed_job, class: 'Delayed::Job' do
    job_group { create(:job_group) }
  end
end
