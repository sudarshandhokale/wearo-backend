class User < ApplicationRecord
  TERMS_VERSION = AppConfig.fetch(:terms_version, default: "2026-08-12").freeze
  PRIVACY_VERSION = AppConfig.fetch(:privacy_version, default: "2026-08-12").freeze

  attr_accessor :accept_terms, :accept_privacy, :accept_ai_processing, :confirm_adult

  devise :database_authenticatable, :validatable

  has_one :style_profile, dependent: :destroy
  has_one :wardrobe, dependent: :destroy
  has_many :outfits, dependent: :destroy
  has_many :clothing_items, dependent: :destroy
  has_many :recommendation_requests, dependent: :destroy
  has_many :ai_requests, dependent: :destroy
  has_many :wear_histories, dependent: :destroy
  has_many :outfit_feedbacks, dependent: :destroy
  has_many :styling_plans, dependent: :destroy
  has_many :outfit_visualizations, dependent: :destroy
  has_one_attached :full_body_image

  validates :first_name, :timezone, :country_code, presence: true
  validates :accept_terms, :accept_privacy, :accept_ai_processing, :confirm_adult,
            acceptance: { accept: [ true, "true", "1" ] },
            on: :create
  validates :full_body_image,
            content_type: %w[image/png image/jpeg image/webp],
            size: { less_than_or_equal_to: 10.megabytes }

  before_validation :normalize_email
  before_validation :normalize_country_code
  before_validation :set_default_timezone
  before_create :record_registration_consents
  before_update :increment_token_version, if: :will_save_change_to_encrypted_password?
  after_create :create_default_profile_records

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
  end

  def confirmed?
    confirmed_at.present?
  end

  def ai_processing_consented?
    ai_processing_consent_at.present?
  end

  def record_current_consents!(attributes)
    timestamp = Time.current
    updates = {}
    if truthy?(attributes[:accept_terms])
      updates.merge!(terms_accepted_at: timestamp, terms_version: TERMS_VERSION)
    end
    if truthy?(attributes[:accept_privacy])
      updates.merge!(privacy_accepted_at: timestamp, privacy_version: PRIVACY_VERSION)
    end
    updates[:ai_processing_consent_at] = timestamp if truthy?(attributes[:accept_ai_processing])
    updates[:adult_confirmed_at] = timestamp if truthy?(attributes[:confirm_adult])
    update!(updates) if updates.any?
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def normalize_country_code
    self.country_code = country_code.to_s.upcase.presence || "US"
  end

  def set_default_timezone
    self.timezone = timezone.presence || "UTC"
  end

  def create_default_profile_records
    create_style_profile!
    create_wardrobe!(name: Wardrobe::DEFAULT_NAME)
  end

  def record_registration_consents
    timestamp = Time.current
    self.terms_accepted_at = timestamp
    self.terms_version = TERMS_VERSION
    self.privacy_accepted_at = timestamp
    self.privacy_version = PRIVACY_VERSION
    self.ai_processing_consent_at = timestamp
    self.adult_confirmed_at = timestamp
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def increment_token_version
    self.token_version += 1
  end
end
