class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  validates :first_name, :timezone, :country_code, presence: true

  before_validation :normalize_email
  before_validation :normalize_country_code
  before_validation :set_default_timezone

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
end
