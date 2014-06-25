# Delayed::Cron::Job

Delayed Cron Job is an extension to Delayed::Job that allows you to set
cron expressions for your jobs to run regularly.

## Installation

Add this line to your application's Gemfile:

    gem 'delayed_cron_job'

And then execute:

    $ bundle

If you are using `delayed_job_active_record`, generate a migration to add
the `cron` column to the `delayed_jobs` table:

    $ rails generate delayed_jobs:cron
    $ rake db:migrate

There are no additional steps for `delayed_job_mongoid`.

## Usage

When enqueuing a job, simply pass the `cron` option, e.g.:

    Delayed::Job.enqueue(MyRepetitiveJob.new, cron: '15 */6 * * 1-5')

Any crontab compatible cron expressions are supported.
The corresponding `Cronline` class from https://github.com/jmettraux/rufus-scheduler is used.

The initial `run_at` value is computed during the `#enqueue` method call.
If you create `Delayed::Job` database entries directly, make sure to set `run_at`
accordingly.

You may use the `id` of the `Delayed::Job` as returned by the `#enqueue` method
to reference and/or remove the scheduled job in the future.

## Contributing

1. Fork it ( https://github.com/codez/delayed_cron_job/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
