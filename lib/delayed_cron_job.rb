require 'delayed_job'
require 'English'
require 'delayed_cron_job/cronline'
require 'delayed_cron_job/plugin'
require 'delayed_cron_job/version'

module DelayedCronJob

end

if defined?(Delayed::Backend::Mongoid)
  Delayed::Backend::Mongoid::Job.field :cron, :type => String
  Delayed::Backend::Mongoid::Job.attr_accessible(:cron) if Delayed::Backend::Mongoid::Job.respond_to?(:attr_accessible)
end

if defined?(Delayed::Backend::ActiveRecord) && Delayed::Backend::ActiveRecord::Job.respond_to?(:attr_accessible)
  Delayed::Backend::ActiveRecord::Job.attr_accessible(:cron)
end

Delayed::Worker.plugins << DelayedCronJob::Plugin
