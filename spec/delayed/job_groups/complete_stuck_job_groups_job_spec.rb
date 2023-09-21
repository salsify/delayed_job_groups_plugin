# frozen_string_literal: true

describe Delayed::JobGroups::CompleteStuckJobGroupsJob do
  describe "#perform" do
    let(:job) { described_class.new }

    let!(:blocked) { create(:job_group, blocked: true) }
    let!(:not_queueing_complete) { create(:job_group, queueing_complete: false) }
    let!(:ready_without_jobs) { create(:job_group, queueing_complete: true, blocked: false) }
    let!(:ready_with_jobs) do
      create(:job_group, queueing_complete: true, blocked: false).tap do |job_group|
        create(:delayed_job, job_group: job_group)
      end
    end

    before do
      allow(Delayed::JobGroups::JobGroup).to receive(:check_for_completion)
    end

    it "checks all relevant job groups for completion" do
      job.perform

      expect(Delayed::JobGroups::JobGroup).to have_received(:check_for_completion)
                                                .once
                                                .with(ready_without_jobs.id, skip_pending_jobs_check: true)
    end
  end

  describe "#enqueue" do
    before do
      allow(Delayed::Job).to receive(:enqueue)
    end

    it "enqueues the job" do
      described_class.enqueue

      expect(Delayed::Job).to have_received(:enqueue).with(instance_of(described_class))
    end
  end
end
