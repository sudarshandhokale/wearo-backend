class Wardrobe < ApplicationRecord
  DEFAULT_NAME = "My Wardrobe"

  belongs_to :user

  validates :name, presence: true
end
