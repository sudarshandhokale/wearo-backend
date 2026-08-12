class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  has_one :style_profile, dependent: :destroy
  has_one :wardrobe, dependent: :destroy
  has_many :outfits, dependent: :destroy
  has_many :clothing_items, dependent: :destroy
  has_many :recommendation_requests, dependent: :destroy
  has_many :ai_requests, dependent: :destroy

  validates :first_name, :timezone, :country_code, presence: true

  before_validation :normalize_email
  before_validation :normalize_country_code
  before_validation :set_default_timezone
  after_create :create_default_profile_records

  def full_name
    [ first_name, last_name ].compact_blank.join(" ")
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
end
