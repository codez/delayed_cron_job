require 'delayed_job'
require 'english'
require 'delayed_cron_job/cronline'
require 'delayed_cron_job/plugin'
require 'delayed_cron_job/version'

module DelayedCronJob

end

DelayedCronJob::Plugin.callback_block.call(Delayed::Worker.lifecycle)