

describe DelayedCronJob do

  class TestJob
    def perform; end
  end

  before { Delayed::Job.delete_all }

  let(:cron)    { '5 1 * * *' }
  let(:handler) { TestJob.new }
  let(:job)     { Delayed::Job.enqueue(handler, cron: cron) }
  let(:worker)  { Delayed::Worker.new }
  let(:now)     { Delayed::Job.db_time_now }
  let(:next_run) do
    run = now.hour * 60 + now.min >= 65 ? now + 1.day : now
    Time.utc(run.year, run.month, run.day, 1, 5)
  end

  context 'with cron' do
    it 'sets run_at on enqueue' do
      expect { job }.to change { Delayed::Job.count }.by(1)
      expect(job.run_at).to eq(next_run)
    end

    it 'schedules a new job after success' do
      job.update_column(:run_at, now)

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).not_to eq(job.id)
      expect(j.cron).to eq(job.cron)
      expect(j.run_at).to eq(next_run)
      expect(j.attempts).to eq(1)
    end

    it 'schedules a new job after failure' do
      allow_any_instance_of(TestJob).to receive(:perform).and_raise('Fail!')
      job.update_column(:run_at, now)

      worker.work_off

      expect(Delayed::Job.count).to eq(1)
      j = Delayed::Job.first
      expect(j.id).not_to eq(job.id)
      expect(j.cron).to eq(job.cron)
      expect(j.run_at).to eq(next_run)
      expect(j.last_error).to match('Fail!')
      expect(j.attempts).to eq(1)
    end

    it 'schedules a new job after timeout'
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