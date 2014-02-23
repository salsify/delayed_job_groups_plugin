# encoding: UTF-8

require 'active_support'
require 'active_record'
require 'delayed_job'
require 'delayed_job_active_record'
require 'delayed/job_groups/compatibility'
require 'delayed/job_groups/job_extensions'
require 'delayed/job_groups/job_group'
require 'delayed/job_groups/plugin'
require 'delayed/job_groups/version'

Delayed::Backend::ActiveRecord::Job.send(:include, Delayed::JobGroups::JobExtensions)

Delayed::Worker.plugins << Delayed::JobGroups::Plugin
