class DataRetentionCleanupJob < ApplicationJob
  queue_as :default

  def perform
    remove_expired_denylist_records
    remove_abandoned_registrations
    remove_failed_visualizations
    purge_completed_request_references
  end

  private

  def remove_expired_denylist_records
    JwtDenylist.where(exp: ...Time.current).delete_all
  end

  def remove_abandoned_registrations
    User.where(confirmed_at: nil, created_at: ...7.days.ago).find_each do |user|
      Accounts::Erase.erase_unverified!(user)
    end
  end

  def remove_failed_visualizations
    OutfitVisualization.failed.where(updated_at: ...7.days.ago).find_each(&:destroy!)
  end

  def purge_completed_request_references
    OutfitVisualization.where.not(completed_at: nil).where(updated_at: ...1.hour.ago).find_each do |visualization|
      visualization.reference_image.purge_later if visualization.reference_image.attached?
    end
  end
end
