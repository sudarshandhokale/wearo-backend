class Stylist::RecommendationSerializer < ApplicationSerializer
  attributes :context, :outfits

  def context
    object.context
  end

  def outfits
    object.outfits.map do |outfit|
      Outfit::ViewSerializer.new(outfit).serializable_hash
    end
  end
end
