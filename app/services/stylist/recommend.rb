module Stylist
  class Recommend
    class << self
      def call(user:, prompt:)
        extracted_context = ExtractContext.call(prompt, timezone: user.timezone)
        candidates = CandidateSelector.call(user: user, context: extracted_context.attributes)
        suggestions = WardrobeSuggestions.call(candidates: candidates, context: extracted_context.attributes)
        combinations = CombinationBuilder.call(candidates: candidates, context: extracted_context.attributes)
        scored_combinations = combinations.map do |combination|
          CompatibilityScorer.call(
            combination: combination,
            context: extracted_context.attributes,
            style_profile: user.style_profile
          )
        end
        ranked_combinations = RankRecommendations.call(
          scored_combinations: scored_combinations,
          prompt: prompt,
          context: extracted_context.attributes
        )

        outfits = persist_outfits(
          user: user,
          prompt: prompt,
          extracted_context: extracted_context,
          ranked_combinations: ranked_combinations
        )

        RecommendationResult.new(context: extracted_context.attributes, outfits: outfits, suggestions: suggestions)
      end

      private

      def persist_outfits(user:, prompt:, extracted_context:, ranked_combinations:)
        Outfit.transaction do
          ranked_combinations.map do |ranked_combination|
            outfit = user.outfits.create!(
              prompt: prompt,
              occasion: extracted_context.attributes["occasion"],
              context: extracted_context.attributes,
              recommendation_score: ranked_combination.score,
              explanation: ranked_combination.explanation,
              status: :recommended,
              recommended_for: extracted_context.recommended_for
            )

            ranked_combination.items.each_with_index do |(role, clothing_item), position|
              outfit.outfit_items.create!(
                clothing_item: clothing_item,
                role: role,
                position: position
              )
            end
            outfit
          end
        end
      end
    end
  end
end
