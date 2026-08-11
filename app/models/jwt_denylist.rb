class JwtDenylist < ApplicationRecord
  self.table_name = "jwt_denylist"

  validates :jti, :exp, presence: true
  validates :jti, uniqueness: true

  scope :active, -> { where("exp > ?", Time.current) }

  def self.revoked?(jti)
    active.exists?(jti: jti)
  end
end
