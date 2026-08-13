class RoutineSchedulerJob < ApplicationJob
  queue_as :default

  INTERVAL = 15.minutes
  LOCK_KEY = "wearo:#{Rails.env}:routine_scheduler"
  LOCK_TTL = 10.minutes.to_i

  def perform
    return unless scheduler_lock_acquired?

    Routines::ScheduleOccurrences.call
  ensure
    self.class.set(wait: INTERVAL).perform_later if !Rails.env.test? && scheduler_lock_acquired
  end

  private

  attr_reader :scheduler_lock_acquired

  def scheduler_lock_acquired?
    @scheduler_lock_acquired = Sidekiq.redis do |redis|
      redis.set(LOCK_KEY, SecureRandom.uuid, nx: true, ex: LOCK_TTL)
    end
  end
end
