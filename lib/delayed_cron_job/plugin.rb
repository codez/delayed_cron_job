module DelayedCronJob
  class Plugin < Delayed::Plugin
    callbacks do |lifecycle|

      lifecycle.around(:error) do |worker, job, &block|
        if job.cron
          # Prevent rescheduling of failed jobs as this is already done
          # after perform
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

      lifecycle.after(:perform) do |worker, job|
        if job.cron?
          # schedule the next run
          next_job = job.dup
          next_job.attempts += 1
          next_job.run_at = Cronline.new(job.cron).next_time(Delayed::Job.db_time_now)
          next_job.save!
        end
      end

    end
  end
end