require 'delayed_cron_job'

describe DelayedCronJob do
  context 'with cron' do
    it 'sets run_at on enqueue'
    it 'schedules a new job after success'
    it 'schedules a new job after failure'
    it 'destroys the original job after a single failure'
    it 'uses correct db time for next run'
    it 'increases attempts on each run'
    it 'is not stopped by max attempts'
  end

  context 'without cron' do
    it 'reschedules the original job after a single failure'
    it 'does not reschedule a job after a run'
  end
end