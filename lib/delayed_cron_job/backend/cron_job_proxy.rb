module DelayedCronJob
  module Backend
    class CronJobProxy
      instance_methods.each do |m|
        undef_method(m) unless m =~ /(^__|^nil\?$|^send$|^object_id$)/
      end

      def initialize(target)
        @target = target
      end

      def destroy
        if cron.present?
          # intercept and reschedule the existing record, instead
          reschedule
        else
          super
        end
      end

      def respond_to?(symbol, include_priv=false)
        @target.respond_to?(symbol, include_priv)
      end

      def ==(other) #:nodoc:
        self.object_id == other.object_id
      end

      private

      def method_missing(method, *args, &block)
        @target.send(method, *args, &block)
      end

      def reschedule
        @target.locked_at = nil
        @target.locked_by = nil
        @target.attempts += 1
        @target.set_next_run_at
        @target.unlock
        @target.save!
      end
    end
  end
end