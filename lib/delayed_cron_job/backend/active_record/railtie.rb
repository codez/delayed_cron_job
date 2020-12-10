module DelayedCronJob
  module Backend
    module ActiveRecord
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          Delayed::Backend::ActiveRecord::Job.send(:include, DelayedCronJob::Backend::UpdatableCron)
          if Delayed::Backend::ActiveRecord::Job.respond_to?(:attr_accessible)
            Delayed::Backend::ActiveRecord::Job.attr_accessible(:cron)
          end
        end
      end
    end
  end
end
