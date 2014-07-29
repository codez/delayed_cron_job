require 'delayed_job'
require 'English'
require 'delayed_cron_job/cronline'
require 'delayed_cron_job/plugin'
require 'delayed_cron_job/version'

module DelayedCronJob

end

if defined?(Delayed::Backend::Mongoid)
  Delayed::Backend::Mongoid::Job.field :cron, :type => String
end

DelayedCronJob::Plugin.callback_block.call(Delayed::Worker.lifecycle)
