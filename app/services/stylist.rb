module Stylist
  ExtractedContext = Data.define(:attributes, :recommended_for)
  Combination = Data.define(:items)
  ScoredCombination = Data.define(:items, :score, :score_breakdown)
  RankedCombination = Data.define(:items, :score, :score_breakdown, :explanation, :ranking_metadata)

  class RecommendationResult
    include ActiveModel::Model

    attr_accessor :context, :outfits
  end

  class Error < StandardError; end
  class InvalidPromptError < Error; end
  class InsufficientWardrobeError < Error
    attr_reader :missing_roles

    def initialize(missing_roles)
      @missing_roles = missing_roles
      super("Wardrobe is missing required clothing roles")
    end
  end
  class InvalidRankingError < Error; end
  class ConfigurationError < Error; end
  class ProviderError < Error; end
end
