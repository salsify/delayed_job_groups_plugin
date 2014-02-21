# Delayed Job Groups
[![Build Status](https://secure.travis-ci.org/salsify/delayed_job_groups.png?branch=master)][travis]
[![Code Climate](https://codeclimate.com/github/salsify/delayed_job_groups.png)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/salsify/delayed_job_groups/badge.png?branch=master)][coveralls]

[travis]: http://travis-ci.org/salsify/delayed_job_groups
[codeclimate]: https://codeclimate.com/github/salsify/delayed_job_groups
[coveralls]: https://coveralls.io/r/salsify/delayed_job_groups

A [Delayed Job](https://github.com/collectiveidea/delayed_job) plugin that adds job groups supporting:

* Canceling all jobs in a job group
* Canceling the job group when a job in the job group fails
* Blocking and unblocking all jobs in a job group
* Running additional processing after all jobs in a job group complete or a job group fails

## Installation

Add this line to your application's Gemfile:

    gem 'delayed_job_groups'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install delayed_job_groups

Run the required database migrations:

    $ rails generate delayed_job_groups:install
    $ rake db:migrate

Update your Delayed Job initializer to register the plugin:

```ruby
require 'delayed_job_groups'
Delayed::Worker.plugins << Delayed::JobGroups::Plugin
```

## Usage

Creating a job group and queuing some jobs:

```ruby
job_group = Delayed::JobGroups::JobGroup.create!

# JobGroup#enqueue has the same signature as Delayed::Job.enqueue 
# i.e. it takes a job and an optional hash of options.
job_group.enqueue(MyJob.new('some arg'), queue: 'general')
job_group.enqueue(MyJob.new('some other arg'), queue: 'general', priority: 10)

# Tell the JobGroup we're done queueing jobs
job_group.mark_queueing_complete
```

Registering a job to run after all jobs in the job group have completed:

```ruby
# We can optionally pass options that will be used when queueing the on completion job
job_group = Delayed::JobGroups::JobGroup.create!(on_completion_job: MyCompletionJob.new, 
                                                 on_completion_job_options: { queue: 'general' })
```

Registering a job to run if the job group is canceled or fails:

```ruby
# We can optionally pass options that will be used when queueing the on cancellation job
job_group = Delayed::JobGroups::JobGroup.create!(on_cancellation_job: MyCancellationJob.new, 
                                                 on_cancellation_job_options: { queue: 'general' })
```

Block and unblock jobs in a job group:

```ruby
# Construct the JobGroup in a blocked state
job_group = Delayed::JobGroups::JobGroup.create!(blocked: true)
job_group.enqueue(MyJob.new('some arg'), queue: 'general')
job_group.mark_queueing_complete
 
# Do more stuff...
 
# Unblock the JobGroup so its jobs can run
job_group.unblock
```

Cancel a job group:

```ruby
job_group = Delayed::JobGroups::JobGroup.create!
 
# Do more stuff...
 
job_group.cancel
```

## Supported Platforms

* Only the Delayed Job Active Record backend is supported.
* Tested with Rails 3.2 and 4.0.
* Tested with MRI 1.9.3, 2.0.0, 2.1.0 and JRuby in 1.9 mode.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
