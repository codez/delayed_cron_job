module DelayedCronJob
  class Plugin < Delayed::Plugin

    class << self
      def next_run_at(job)
        job.run_at = Cronline.new(job.cron).next_time(Delayed::Job.db_time_now)
      end

      def cron?(job)
        job.cron.present?
      end
    end

    callbacks do |lifecycle|
      # Calculate the next run_at based on the cron attribute before enqueue.
      lifecycle.before(:enqueue) do |job|
        next_run_at(job) if cron?(job)
      end

      # Prevent rescheduling of failed jobs as this is already done
      # after perform.
      lifecycle.around(:error) do |worker, job, &block|
        if cron?(job)
          job.last_error = "#{$ERROR_INFO.message}\n#{$ERROR_INFO.backtrace.join("\n")}"
          worker.job_say(job,
                         "FAILED with #{$ERROR_INFO.class.name}: #{$ERROR_INFO.message}",
                         Logger::ERROR)
          job.destroy
        else
          # No cron job - proceed as normal
          block.call(worker, job)
        end
      end

      # Schedule the next run based on the cron attribute.
      lifecycle.after(:perform) do |worker, job|
        if cron?(job)
          next_job = job.dup
          next_job.id = job.id
          next_job.locked_at = nil
          next_job.locked_by = nil
          next_job.attempts += 1
          next_run_at(next_job)
          next_job.save!
        end
      end
    end

  end
end