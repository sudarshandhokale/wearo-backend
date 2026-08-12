class Stylist::RecommendationSerializer < ApplicationSerializer
  attributes :recommendation, :context, :outfits, :suggestions

  def recommendation
    RecommendationRequest::ViewSerializer.new(object.recommendation_request).serializable_hash.except(:outfits)
  end

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
