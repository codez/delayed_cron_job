module DelayedCronJob
  class Plugin < Delayed::Plugin

    class << self
      def cron?(job)
        job.cron.present?
      end
    end

    callbacks do |lifecycle|

      # Prevent rescheduling of failed jobs as this is already done
      # after perform.
      lifecycle.around(:error) do |worker, job, &block|
        if cron?(job)
          job.error = $ERROR_INFO
          worker.job_say(job,
                         "FAILED with #{$ERROR_INFO.class.name}: #{$ERROR_INFO.message}",
                         Logger::ERROR)
          job.destroy
        else
          # No cron job - proceed as normal
          block.call(worker, job)
        end
      end

      # Reset the last_error to have the correct status of the last run.
      lifecycle.before(:perform) do |worker, job|
        if cron?(job)
          job.last_error = nil
        end
      end

      # Wrap the job in a proxy that will intercept destroy and reschedule the job record, instead.
      lifecycle.around(:perform) do |worker, job, &block|
        if cron?(job)
          block.binding.local_variable_set(:job, DelayedCronJob::Backend::CronJobProxy.new(job))
        end
        block.call
      end

      # Update the cron expression from the database in case it was updated.
      lifecycle.after(:invoke_job) do |job|
        if cron?(job)
          job.cron = job.class.where(:id => job.id).pluck(:cron).first
        end
      end
    end

  end
end
