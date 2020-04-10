# Delayed::Cron::Job

[![Build Status](https://travis-ci.org/codez/delayed_cron_job.svg)](https://travis-ci.org/codez/delayed_cron_job)

Delayed::Cron::Job is an extension to Delayed::Job that allows you to set
cron expressions for your jobs to run repeatedly.

## Installation

Add the following line to your application's Gemfile. Add it after the lines for all other `delayed_job*` gems so the gem can properly integrate with the Delayed::Job code.

    gem 'delayed_cron_job'

And then execute:

    $ bundle

If you are using `delayed_job_active_record`, generate a migration (after the
original delayed job migration) to add the `cron` column to the `delayed_jobs`
table:

    $ rails generate delayed_job:cron
    $ rake db:migrate

There are no additional steps for `delayed_job_mongoid`.

## Usage

When enqueuing a job, simply pass the `cron` option, e.g.:

    Delayed::Job.enqueue(MyRepeatedJob.new, cron: '15 */6 * * 1-5')

Or, when using ActiveJob:

    MyJob.set(cron: '*/5 * * * *').perform_later

Any crontab compatible cron expressions are supported (see `man 5 crontab`).
The credits for the `Cronline` class used go to
[rufus-scheduler](https://github.com/jmettraux/rufus-scheduler).

## Scheduling

Usually, you want to schedule all existing cron jobs when deploying the
application. Using a common super class makes this simple.

### Custom CronJob superclass

`app/jobs/cron_job.rb`:

```ruby
# Default configuration in `app/jobs/application_job.rb`, or subclass
# ActiveJob::Base .
class CronJob < ApplicationJob

  class_attribute :cron_expression

  class << self

    def schedule
      set(cron: cron_expression).perform_later unless scheduled?
    end

    def remove
      delayed_job.destroy if scheduled?
    end

    def scheduled?
      delayed_job.present?
    end

    def delayed_job
      Delayed::Job
        .where('handler LIKE ?', "%job_class: #{name}%")
        .first
    end

  end
end
```

### Example Job inheriting from CronJob

Then, an example job that triggers E-Mail-sending with default cron time at
noon every day:

`app/jobs/noon_job.rb`:

```ruby

# Note that it inherits from `CronJob`
class NoonJob < CronJob
  # set the (default) cron expression
  self.cron_expression '0 12 * * *'

  # will enqueue the mailing delivery job
  def perform
    UserMailer.daily_notice(User.first).deliver_later
  end
end
```

### Scheduling "trigger"

Jobs with a `cron` definition are rescheduled automatically only when a job
instance finished its work. So there needs to be an initial scheduling of all
cron jobs. If you do not want to do this manually (e.g. using `rails console`)
or with your application logic, you can e.g. hook into the `rails db:*` rake
tasks:

Define some helpers:

`app/lib/scheduled_job_check.rb`:

```ruby

class ScheduledJobCheck
  def self.all_cron_job_classes
    # Need to load all jobs definitions in order to find subclasses
    # (or: understand Zeitwerk)
    glob = Rails.root.join('app', 'jobs', '**', '*_job.rb')
    Dir.glob(glob).each {|f| require f}
    CronJob.subclasses
  end

  # true iff all CronJob descendents are present with an instance in the
  # database
  def self.all_scheduled?
    all_cron_job_classes.all? { |job| job.scheduled? }
  end

  # schedule all CronJob descendents that are not already scheduled
  def self.schedule_all!
    all_cron_job_classes.each { |job| job.scheduled }
  end
end
```

And define a rake task and enhance `db:migrate` and `db:schema:load` to use it.

`lib/tasks/jobs.rake`:

```ruby
namespace :db do
  desc 'Schedule all cron jobs'
  task :schedule_jobs => :environment do
    ScheduledJobCheck.schedule_all!
  end
end

# invoke schedule_jobs automatically after every migration and schema load.
%w(db:migrate db:schema:load).each do |task|
  Rake::Task[task].enhance do
    Rake::Task['db:schedule_jobs'].invoke
  end
end
```

Now, if you run `rails db:migrate`, `rails db:schema:load` or `rails
db:schedule_jobs` all jobs inheriting from `CronJob` are scheduled.

*If you are not using ActiveJob, the same approach may be used with minor
adjustments.*

### Cheap "health"-display of schedules

If you have an admin controller or some place where you want to show whether or
not all `CronJob`s are scheduled as expected, you can add the following snippets
to your controller to show a flash if some schedule is missing. You can also
expose a controller action to trigger `ScheduledJobCheck.schedule_all!` .

`app/controller/admin_controller.rb`:

```ruby
# ...
  def index
    if !ScheduledJobCheck.all_scheduled?
      flash.now[:error] = t('.problem_not_all_jobs_scheduled')
    end
    # ... whatever AdminController does, e.g.
    @jobs = Delayed::Job.all
    # ...
  end
# ...
```

### Changing the schedule

Note that if you have a CronJob scheduled and change its `cron_expression` in
its source file, you will have to remove any scheduled instances of the Job and
reschedule it (e.g. with the snippet above: `rails db:migrate`). This is because
the `cron_expression` is already persisted in the database (as `cron`).

## Details

The initial `run_at` value is computed during the `#enqueue` method call.
If you create `Delayed::Job` database entries directly, make sure to set
`run_at` accordingly.

You may use the `id` of the `Delayed::Job` as returned by the `#enqueue` method
to reference and/or remove the scheduled job in the future.

The subsequent run of a job is only scheduled after the current run has
terminated. If a single run takes longer than the given execution interval,
some runs may be skipped. E.g., if a run takes five minutes, but the job is
scheduled to be executed every second minute, it will actually only execute
every sixth minute: With a cron of `*/2 * * * *`, if the current run starts at
`:00` and finishes at `:05`, then the next scheduled execution time is at `:06`,
and so on.

If you do not want longer running jobs to skip executions, simply create a
lightweight master job that enqueues the actual workload as separate jobs.
Of course you have to make sure to start enough workers to handle all these
jobs.

## Contributing

1. Fork it ( https://github.com/codez/delayed_cron_job/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Delayed::Cron::Job is released under the terms of the MIT License.
Copyright 2014-2019 Pascal Zumkehr. See LICENSE for further information.
