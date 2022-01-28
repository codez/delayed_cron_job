module DelayedCronJob
  module Backend
    module ActiveRecord
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          Delayed::Job.include(DelayedCronJob::Backend::UpdatableCron)
        end
      end
    end
  end
end
