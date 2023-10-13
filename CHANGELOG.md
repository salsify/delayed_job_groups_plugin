# Changelog

## 0.10.0

- Add support for Rails 7.1

## 0.9.0
- Add a `CompleteStuckJobGroupsJob`, which can be run periodically to close "stuck" job groups
- Drop support for Ruby 2.7
- Drop support for Rails 6.0

## 0.8.0
- Drop support for ruby < 2.7
- Add support for ruby 3.1
- Drop Rails 5.2
- Add Rails 7.0

## 0.7.0
* Add support for ruby 3
* Drop support for ruby < 2.6

## 0.6.2
* Defer including extension until delayed_job_active_record is loaded

## 0.6.1
* Fix job_group_id `belongs_to` behavior when `config.active_record.belongs_to_required_by_default` is enabled.

## 0.6.0
* Add support for Rails 6.1.

## 0.5.0
* Drop support for Ruby 2.3 and 2.4.
* Drop support for Rails < 5.2.
* Bugfix for rails version in generated migration files

## 0.4.3
* Bugfix for `on_completion_job` when `failure_cancels_group` is set to false.

## 0.4.2
* Add support for Rails 6.0.

## 0.4.1
* Bugfix for `on_completion_job` and `on_cancellation_job` YAML serialization

## 0.4.0
* Drop support for Ruby 2.0, 2.1 and 2.2.
* Add support for Ruby 2.5.
* Drop support for Rails < 4.2.
* Add support for Rails 5.2

## 0.3.0
* Drop support for Ruby 1.9 and 2.0.

## 0.2.0
* Change supported delayed job version
* Clean up lifecycle management in plugin

## 0.1.3
* Change supported rails version.

## 0.1.2
* Add configuration option to allow failed jobs not to cancel a group.

## 0.1.1
* Update the run_at for all jobs in a JobGroup when it's unblocked.
