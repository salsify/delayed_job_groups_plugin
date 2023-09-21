# frozen_string_literal: true

describe Delayed::JobGroups::JobGroup do

  let(:blocked) { false }
  let(:on_completion_job) { 'dummy on completion job' }
  let(:on_completion_job_options) do
    { foo: 'bar' }
  end
  let(:current_time) { Time.utc(2013) }

  subject(:job_group) do
    create(
      :job_group,
      on_completion_job: on_completion_job,
      on_completion_job_options: on_completion_job_options,
      blocked: blocked
    )
  end

  before do
    Timecop.freeze(current_time)
    allow(Delayed::Job).to receive(:enqueue)
  end

  after do
    Timecop.return
  end

  describe "scopes" do
    describe "ready" do
      let!(:blocked) { create(:job_group, blocked: true) }
      let!(:not_queueing_complete) { create(:job_group, queueing_complete: false) }
      let!(:ready) { create(:job_group, queueing_complete: true, blocked: false) }

      it "returns the expected job groups" do
        expect(described_class.ready).to match_array(ready)
      end
    end

    describe "with_no_open_jobs" do
      let!(:job_group_with_jobs) { create(:delayed_job).job_group }
      let!(:job_group_without_jobs) { subject }

      it "returns groups with no jobs" do
        expect(described_class.with_no_open_jobs).to match_array(job_group_without_jobs)
      end
    end
  end

  shared_examples "the job group was completed" do
    it "queues the completion job" do
      expect(Delayed::Job).to have_received(:enqueue).with(on_completion_job, on_completion_job_options)
    end

    it "destroys the job group" do
      expect(job_group).to have_been_destroyed
    end
  end

  shared_examples "the job group was not completed" do
    it "does not queue the completion job" do
      expect(Delayed::Job).not_to have_received(:enqueue)
    end

    it "does not destroy the job group" do
      expect(job_group).not_to have_been_destroyed
    end
  end

  describe "#mark_queueing_complete" do

    context "when no jobs exist" do
      before { job_group.mark_queueing_complete }

      it { is_expected.to be_queueing_complete }

      it_behaves_like "the job group was completed"
    end

    context "when no jobs exist but the job group is blocked" do
      let(:blocked) { true }

      before { job_group.mark_queueing_complete }

      it { is_expected.to be_queueing_complete }

      it_behaves_like "the job group was not completed"
    end

    context "when active jobs exist" do
      before do
        Delayed::Job.create!(job_group_id: job_group.id)
        job_group.mark_queueing_complete
      end

      it { is_expected.to be_queueing_complete }

      it_behaves_like "the job group was not completed"
    end
  end

  describe "instance check_for_completion" do
    let!(:job) { Delayed::Job.create!(job_group_id: job_group.id) }

    before do
      job_group.mark_queueing_complete
    end

    shared_context "complete job and check job group complete" do
      before do
        job.destroy
        job_group.check_for_completion
      end
    end

    context "when no jobs exist" do
      include_context "complete job and check job group complete"

      it_behaves_like "the job group was completed"
    end

    context "when active jobs exist" do
      before do
        Delayed::JobGroups::JobGroup.check_for_completion(job_group.id)
      end

      it_behaves_like "the job group was not completed"
    end

    context "when on failed jobs exist" do
      before do
        job.update!(failed_at: Time.now)
        Delayed::JobGroups::JobGroup.check_for_completion(job_group.id)
      end

      it_behaves_like "the job group was completed"
    end

    context "when there are no on_completion_job_options" do
      let(:on_completion_job_options) { nil }

      include_context "complete job and check job group complete"

      it "queues the completion job with empty options" do
        expect(Delayed::Job).to have_received(:enqueue).with(on_completion_job, {})
      end

      it "destroys the job group" do
        expect(job_group).to have_been_destroyed
      end
    end

    context "when there is no on_completion_job" do
      let(:on_completion_job) { nil }

      include_context "complete job and check job group complete"

      it "doesn't queues the non-existent completion job" do
        expect(Delayed::Job).not_to have_received(:enqueue)
      end

      it "destroys the job group" do
        expect(job_group).to have_been_destroyed
      end
    end
  end

  describe "class check_for_completion" do
    let!(:job) { Delayed::Job.create!(job_group_id: job_group.id) }

    before do
      job_group.mark_queueing_complete
    end

    shared_context "complete job and check job group complete" do
      before do
        job.destroy
        Delayed::JobGroups::JobGroup.check_for_completion(job_group.id)
      end
    end

    context "when no jobs exist" do
      include_context "complete job and check job group complete"

      it_behaves_like "the job group was completed"
    end

    context "when active jobs exist" do
      before do
        Delayed::JobGroups::JobGroup.check_for_completion(job_group.id)
      end

      it_behaves_like "the job group was not completed"
    end

    context "when on failed jobs exist" do
      before do
        job.update!(failed_at: Time.now)
        Delayed::JobGroups::JobGroup.check_for_completion(job_group.id)
      end

      it_behaves_like "the job group was completed"
    end

    context "when there are no on_completion_job_options" do
      let(:on_completion_job_options) { nil }

      include_context "complete job and check job group complete"

      it "queues the completion job with empty options" do
        expect(Delayed::Job).to have_received(:enqueue).with(on_completion_job, {})
      end

      it "destroys the job group" do
        expect(job_group).to have_been_destroyed
      end
    end

    context "when there is no on_completion_job" do
      let(:on_completion_job) { nil }

      include_context "complete job and check job group complete"

      it "doesn't queues the non-existent completion job" do
        expect(Delayed::Job).not_to have_received(:enqueue)
      end

      it "destroys the job group" do
        expect(job_group).to have_been_destroyed
      end
    end
  end

  describe "#enqueue" do
    let(:job) { 'dummy job' }

    before do
      job_group.enqueue(job)
    end

    shared_examples "it enqueues the job in the correct blocked state" do
      it "enqueues the job in the same blocked state as the job group" do
        expect(Delayed::Job).to have_received(:enqueue).with(job, job_group_id: job_group.id, blocked: blocked)
      end
    end

    it_behaves_like "it enqueues the job in the correct blocked state"

    context "when the job_group is blocked" do
      let(:blocked) { true }

      it_behaves_like "it enqueues the job in the correct blocked state"
    end
  end

  describe "#unblock" do

    context "when the JobGroup isn't blocked" do
      before do
        job_group.unblock
      end

      its(:blocked?) { is_expected.to be(false) }
    end

    context "when the JobGroup is blocked" do
      let(:blocked) { true }

      context "when there are pending jobs" do
        let!(:job) { Delayed::Job.create!(job_group_id: job_group.id, blocked: true) }
        let(:unblock_time) { Time.utc(2014) }

        before do
          job_group.mark_queueing_complete
          Timecop.freeze(unblock_time) { job_group.unblock }
        end

        its(:blocked?) { is_expected.to be(false) }

        it "sets the job's run_at to the unblocked time" do
          expect(job.reload.run_at).to eq unblock_time
        end

        it_behaves_like "the job group was not completed"
      end

      describe "when there are no pending jobs" do
        before do
          job_group.mark_queueing_complete
          job_group.unblock
        end

        its(:blocked?) { is_expected.to be(false) }

        it_behaves_like "the job group was completed"
      end
    end
  end

  describe "#cancel" do
    let!(:queued_job) { Delayed::Job.create!(job_group_id: job_group.id) }
    let!(:running_job)  { Delayed::Job.create!(job_group_id: job_group.id, locked_at: Time.now, locked_by: 'test') }

    before do
      job_group.cancel
    end

    it "destroys the job group" do
      expect(job_group).to have_been_destroyed
    end

    it "destroys queued jobs" do
      expect(queued_job).to have_been_destroyed
    end

    it "does not destroy running jobs" do
      expect(running_job).not_to have_been_destroyed
    end
  end

  describe "#failure_cancels_group?" do
    let(:failure_cancels_group) { true }

    before do
      job_group.update!(failure_cancels_group: failure_cancels_group)
    end

    context "when failures should cancel the group" do
      it "returns true" do
        expect(job_group.failure_cancels_group?).to be true
      end
    end

    context "when failures should not cancel the group" do
      let(:failure_cancels_group) { false }

      it "returns false" do
        expect(job_group.failure_cancels_group?).to be false
      end
    end
  end
end
