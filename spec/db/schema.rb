# encoding: UTF-8

ActiveRecord::Schema.define(:version => 0) do

  create_table(:delayed_jobs, force: true) do |t|
    t.integer :priority, default: 0
    t.integer :attempts, default: 0
    t.text :handler
    t.text :last_error
    t.datetime :run_at
    t.datetime :locked_at
    t.datetime :failed_at
    t.string :locked_by
    t.string :queue
    t.timestamps
    t.boolean :blocked, default: false, null: false
    t.integer :job_group_id
  end
  add_index(:delayed_jobs, :job_group_id)

  create_table(:delayed_job_groups, force: true) do |t|
    t.text :on_completion_job
    t.text :on_completion_job_options
    t.text :on_cancellation_job
    t.text :on_cancellation_job_options
    t.boolean :failure_cancels_group, default: true, null: false
    t.boolean :queueing_complete, default: false, null: false
    t.boolean :blocked, default: false, null: false
  end
end
