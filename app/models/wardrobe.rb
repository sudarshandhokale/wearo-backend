class Wardrobe < ApplicationRecord
  DEFAULT_NAME = "My Wardrobe"

  belongs_to :user
  has_many :clothing_items, dependent: :destroy

  validates :name, presence: true
end
