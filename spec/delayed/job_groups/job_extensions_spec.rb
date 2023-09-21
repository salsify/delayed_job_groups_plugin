# frozen_string_literal: true

describe "delayed job extensions" do
  it "provides an optional job_group_id" do
    job_group = create(:job_group)
    expect(Delayed::Job.new(job_group_id: job_group.id)).to be_valid
    expect(Delayed::Job.new).to be_valid
  end
end
