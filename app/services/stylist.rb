module Stylist
  ExtractedContext = Data.define(:attributes, :recommended_for, :city)
  Combination = Data.define(:items)
  ScoredCombination = Data.define(:items, :score, :score_breakdown)
  RankedCombination = Data.define(:items, :score, :score_breakdown, :name, :explanation, :ranking_metadata)

  class RecommendationResult
    include ActiveModel::Model

    attr_accessor :recommendation_request, :context, :outfits, :suggestions
  end

  class Error < StandardError; end
  class InvalidPromptError < Error; end
  class InsufficientWardrobeError < Error
    attr_reader :missing_roles, :required_combinations

    def initialize(missing_roles, required_combinations:)
      @missing_roles = missing_roles
      @required_combinations = required_combinations
      super("Wardrobe is missing required clothing roles")
    end
  end
  class InvalidRankingError < Error; end
  class RecommendationLimitError < Error; end
  class ConfigurationError < Error; end
  class ProviderError < Error; end
end
