# frozen_string_literal: true

describe Delayed::JobGroups::CompleteStuckJobGroupsJob do
  describe "#perform" do
    let(:job) { described_class.new }

    let!(:blocked) { create(:job_group, blocked: true) }
    let!(:not_queueing_complete) { create(:job_group, queueing_complete: false) }
    let!(:ready) { create(:job_group, queueing_complete: true, blocked: false) }

    before do
      allow(Delayed::JobGroups::JobGroup).to receive(:check_for_completion)
    end

    it "checks all relevant job groups for completion" do
      job.perform

      expect(Delayed::JobGroups::JobGroup).to have_received(:check_for_completion)
                                                .once
                                                .with(ready.id)
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
