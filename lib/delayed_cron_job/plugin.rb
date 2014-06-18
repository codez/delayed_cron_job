module DelayedCronJob
  class Plugin < Delayed::Plugin

    class << self
      def set_next_run(job)
        job.run_at = Cronline.new(job.cron).next_time(Delayed::Job.db_time_now)
      end
    end

    callbacks do |lifecycle|

      # Calculate the next run_at based on the cron attribute before enqueue.
      lifecycle.before(:enqueue) do |job|
        set_next_run(job) if job.cron?
      end

      # Prevent rescheduling of failed jobs as this is already done
      # after perform.
      lifecycle.around(:error) do |worker, job, &block|
        if job.cron?
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
        if job.cron?
          next_job = job.dup
          next_job.attempts += 1
          set_next_run(next_job)
          next_job.save!
        end
      end

    end

  end
end