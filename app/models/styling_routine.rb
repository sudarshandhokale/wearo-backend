class StylingRoutine < ApplicationRecord
  ROUTINE_TYPES = %w[work school_dropoff walking workout social religious custom].freeze
  CITY_MODES = %w[profile fixed].freeze
  OUTFIT_STRATEGIES = %w[separate combine_with_next].freeze

  belongs_to :user
  has_many :occurrences, class_name: "RoutineOccurrence", dependent: :destroy

  before_validation :normalize_days_of_week

  validates :name, presence: true, length: { maximum: 80 }
  validates :routine_type, inclusion: { in: ROUTINE_TYPES }
  validates :days_of_week, :local_time, presence: true
  validates :usage, inclusion: { in: ClothingUsageTaxonomy.keys }
  validates :city_mode, inclusion: { in: CITY_MODES }
  validates :outfit_strategy, inclusion: { in: OUTFIT_STRATEGIES }
  validates :city, presence: true, length: { maximum: 120 }, if: -> { city_mode == "fixed" }
  validates :recommendation_lead_minutes, numericality: { only_integer: true, in: 0..1_440 }
  validate :valid_days_of_week

  scope :active, -> { where(active: true) }
  scope :recent_first, -> { order(created_at: :desc) }

  def city_for_context
    city_mode == "fixed" ? city : user.preferred_city
  end

  private

  def normalize_days_of_week
    self.days_of_week = Array(days_of_week).filter_map { |day| Integer(day, exception: false) }.uniq.sort
  end

  def valid_days_of_week
    errors.add(:days_of_week, :invalid) unless days_of_week.is_a?(Array) && days_of_week.uniq == days_of_week && days_of_week.all? { |day| day.is_a?(Integer) && day.between?(1, 7) }
  end
end
