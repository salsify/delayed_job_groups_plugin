require 'spec_helper'

describe Delayed::JobGroups::Plugin do

  before(:all) do
    Delayed::Worker.plugins << Delayed::JobGroups::Plugin

    @old_max_attempts = Delayed::Worker.max_attempts
    Delayed::Worker.max_attempts = 2
  end

  after(:all) do
    Delayed::Worker.max_attempts = @old_max_attempts
    Delayed::Worker.plugins.delete(Delayed::JobGroups::Plugin)
  end

  before(:each) do
    CompletionJob.invoked = false
    CancellationJob.invoked = false
  end

  let!(:job_group) { Delayed::JobGroups::JobGroup.create!(on_completion_job: CompletionJob.new) }

  it "runs the completion job after completing other jobs" do
    job_group.enqueue(NoOpJob.new)
    job_group.enqueue(NoOpJob.new)
    job_group.mark_queueing_complete
    job_group_count.should eq 1
    queued_job_count.should eq 2

    # Run our first job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    job_group_count.should eq 1
    queued_job_count.should eq 1

    # Run our second job which should enqueue the completion job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    job_group_count.should eq 0
    queued_job_count.should eq 1

    # Now we should run the completion job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_true
    queued_job_count.should eq 0
  end

  it "only runs the completion job after queueing is completed" do
    job_group.enqueue(NoOpJob.new)
    job_group.enqueue(NoOpJob.new)
    job_group_count.should eq 1
    queued_job_count.should eq 2

    # Run our first job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    job_group_count.should eq 1
    queued_job_count.should eq 1

    # Run our second job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    job_group_count.should eq 1
    queued_job_count.should eq 0

    # Mark queueing complete which should queue the completion job
    job_group.mark_queueing_complete
    job_group_count.should eq 0
    queued_job_count.should eq 1

    # Now we should run the completion job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_true
    queued_job_count.should eq 0
  end

  it "cancels the job group if a job fails" do
    Delayed::Worker.max_attempts = 1

    job_group.enqueue(FailingJob.new)
    job_group.enqueue(NoOpJob.new)
    job_group.mark_queueing_complete
    queued_job_count.should eq 2
    job_group_count.should eq 1

    # Run the job which should fail and cancel the JobGroup
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    failed_job_count.should eq 1
    queued_job_count.should eq 0
    job_group_count.should eq 0
  end

  it "doesn't retry failed jobs if the job group has been canceled" do
    job_group.cancel
    Delayed::Job.enqueue(FailingJob.new, job_group_id: job_group.id)
    queued_job_count.should eq 1

    # Run the job which should fail and should not queue a retry
    Delayed::Worker.new.work_off(1)
    failed_job_count.should eq 1
    queued_job_count.should eq 0
  end

  it "doesn't run jobs until they're unblocked" do
    job_group.blocked = true
    job_group.save!

    job_group.enqueue(NoOpJob.new)
    job_group.enqueue(NoOpJob.new)
    job_group.mark_queueing_complete
    Delayed::Job.count.should eq 2

    # No jobs should run because they're blocked
    (successes, failures) = Delayed::Worker.new.work_off
    successes.should eq 0
    failures.should eq 0
    Delayed::Job.count.should eq 2

    job_group.unblock

    # Run our first job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    job_group_count.should eq 1
    Delayed::Job.count.should eq 1

    # Run our second job which should enqueue the completion job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_false
    job_group_count.should eq 0
    Delayed::Job.count.should eq 1

    # Now we should run the completion job
    Delayed::Worker.new.work_off(1)
    CompletionJob.invoked.should be_true
    Delayed::Job.count.should eq 0
  end

  context "when a cancellation job is provided" do
    let!(:job_group) do
      Delayed::JobGroups::JobGroup.create!(on_completion_job: CompletionJob.new,
                                           on_cancellation_job: CancellationJob.new)
    end

    it "runs the cancellation job after a job error causes cancellation" do
      Delayed::Worker.max_attempts = 1

      job_group.enqueue(FailingJob.new)
      job_group.enqueue(NoOpJob.new)
      job_group.mark_queueing_complete
      queued_job_count.should eq 2
      job_group_count.should eq 1

      # Run the job which should fail and cancel the JobGroup
      Delayed::Worker.new.work_off(1)
      CompletionJob.invoked.should be_false
      CancellationJob.invoked.should be_false
      failed_job_count.should eq 1

      queued_job_count.should eq 1
      job_group_count.should eq 0

      # Now we should run the cancellation job
      Delayed::Worker.new.work_off(1)
      CompletionJob.invoked.should be_false
      CancellationJob.invoked.should be_true
      queued_job_count.should eq 0
    end

    it "runs the cancellation job after the job group is cancelled" do
      job_group.enqueue(NoOpJob.new)
      job_group.enqueue(FailingJob.new)
      job_group.mark_queueing_complete
      job_group.cancel

      #cancellation job should be queued
      queued_job_count.should eq 1
      CancellationJob.invoked.should be_false

      # Run the cancellation job
      Delayed::Worker.new.work_off(1)
      CancellationJob.invoked.should be_true
      queued_job_count.should eq 0
    end
  end

  context "when a no completion job is provided" do
    let!(:job_group) {  Delayed::JobGroups::JobGroup.create! }

    it "doesn't queue a non-existent completion job" do
      job_group.enqueue(NoOpJob.new)
      job_group.enqueue(NoOpJob.new)
      job_group.mark_queueing_complete
      job_group_count.should eq 1
      queued_job_count.should eq 2
      failed_job_count.should eq 0

      # Run our first job
      Delayed::Worker.new.work_off(1)
      job_group_count.should eq 1
      queued_job_count.should eq 1
      failed_job_count.should eq 0

      # Run our second job which should delete the job group
      Delayed::Worker.new.work_off(1)
      job_group_count.should eq 0
      queued_job_count.should eq 0
      failed_job_count.should eq 0
    end
  end

  class FailingJob

    def perform
      raise 'Test failure'
    end

  end

  class NoOpJob

    def perform

    end
  end

  class CompletionJob
    cattr_accessor :invoked

    def perform
      CompletionJob.invoked = true
    end
  end

  class CancellationJob
    cattr_accessor :invoked

    def perform
      CancellationJob.invoked = true
    end
  end

  def job_group_count
    Delayed::JobGroups::JobGroup.count
  end

  def queued_job_count
    Delayed::Job.where(failed_at: nil).count
  end

  def failed_job_count
    Delayed::Job.where('failed_at IS NOT NULL').count
  end
end
