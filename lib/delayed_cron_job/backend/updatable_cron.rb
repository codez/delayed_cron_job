module DelayedCronJob
  module Backend
    module UpdatableCron

      def self.included(klass)
        klass.send(:before_save, :set_next_run_at, :if => :cron_changed?)
      end

      def set_next_run_at
        if cron.present?
          self.run_at = Cronline.new(cron).next_time(Delayed::Job.db_time_now)
        end
      end

    end
  end
end