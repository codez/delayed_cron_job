require 'delayed_cron_job'

describe DelayedCronJob do
  context 'with cron' do
    it 'increases attempts on each run'
    it 'is not stopped by max attempts'
    it 'destroys the original job after a single failure'
    it 'schedules a new job after failure'
    it 'schedules a new job after success'
  end

  context 'without cron' do
    it 'reschedules the original job after a single failure'
    it 'does not reschedule a job after a run'
  end
end