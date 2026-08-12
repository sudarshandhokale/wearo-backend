class Stylist::RecommendationSerializer < ApplicationSerializer
  attributes :context, :outfits, :suggestions

  def context
    object.context
  end

  def outfits
    object.outfits.map do |outfit|
      Outfit::ViewSerializer.new(outfit).serializable_hash
    end
  end

  def suggestions
    object.suggestions
  end
end
