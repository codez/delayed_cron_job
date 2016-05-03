# Delayed::Cron::Job

Delayed::Cron::Job is an extension to Delayed::Job that allows you to set
cron expressions for your jobs to run repeatedly.

## Installation

Add this line to your application's Gemfile:

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

Or, when using Active Job:

    MyJob.set(cron: '*/5 * * * *').perform_later

Any crontab compatible cron expressions are supported (see `man 5 crontab`).
The credits for the `Cronline` class used go to
[rufus-scheduler](https://github.com/jmettraux/rufus-scheduler).

You can also pass a method name to the `cron` option, but your payload object
must respond to this method (which receives the job as a parameter) and this 
method must return a valid cron expression. This way, the interval doesn't 
need to be fixed. You can, for example, run the job everyday on the first 
10 days and then just run it once a week. For example:
    
    Delayed::Job.enqueue(MyRepeatedJob.new, cron: :cron_calculator)

```ruby
class MyRepeatedJob < Struct.new
  def perform
  end

  def cron_calculator(job)
    if job.attempts > 10
      '0 0 * * 0'
    else
      '0 0 * * *'
    end
  end
end
```

## Details

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
