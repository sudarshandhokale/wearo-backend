module Stylist
  class Recommend
    DEFAULT_DAILY_RECOMMENDATION_LIMIT = 50

    class << self
      def call(user:, prompt:)
        prompt = prompt.to_s.strip
        recommendation_request = create_recommendation_request!(user, prompt)
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
          context: extracted_context.attributes,
          user: user,
          recommendation_request: recommendation_request
        )

        outfits = persist_outfits(
          user: user,
          recommendation_request: recommendation_request,
          prompt: prompt,
          extracted_context: extracted_context,
          ranked_combinations: ranked_combinations
        )
        complete_recommendation_request!(
          recommendation_request,
          extracted_context: extracted_context,
          suggestions: suggestions,
          ranked_combinations: ranked_combinations
        )

        RecommendationResult.new(
          recommendation_request: recommendation_request,
          context: extracted_context.attributes,
          outfits: outfits,
          suggestions: suggestions
        )
      rescue InvalidPromptError, InsufficientWardrobeError => error
        fail_recommendation_request!(recommendation_request, error)
        raise
      rescue StandardError => error
        fail_recommendation_request!(recommendation_request, error)
        raise
      end

      private

      def create_recommendation_request!(user, prompt)
        raise InvalidPromptError if prompt.blank? || prompt.length > 1_000

        user.with_lock do
          daily_limit = Integer(
            AppConfig.fetch(:stylist_daily_recommendation_limit, default: DEFAULT_DAILY_RECOMMENDATION_LIMIT),
            exception: false
          ).to_i.clamp(1, 10_000)
          local_day = Time.current.in_time_zone(user.timezone).all_day
          raise RecommendationLimitError if user.recommendation_requests.where(created_at: local_day).count >= daily_limit

          user.recommendation_requests.create!(prompt: prompt)
        end
      end

      def persist_outfits(user:, recommendation_request:, prompt:, extracted_context:, ranked_combinations:)
        Outfit.transaction do
          ranked_combinations.map do |ranked_combination|
            outfit = user.outfits.create!(
              recommendation_request: recommendation_request,
              prompt: prompt,
              occasion: extracted_context.attributes["occasion"],
              context: extracted_context.attributes,
              recommendation_score: ranked_combination.score,
              score_breakdown: ranked_combination.score_breakdown,
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

      def complete_recommendation_request!(recommendation_request, extracted_context:, suggestions:, ranked_combinations:)
        ranking_metadata = ranked_combinations.first&.ranking_metadata.to_h.stringify_keys
        ai_request = recommendation_request.ai_requests.order(created_at: :desc).first

        recommendation_request.update!(
          status: :completed,
          context: extracted_context.attributes,
          wardrobe_suggestions: suggestions,
          ranking_source: ranking_metadata["provider"] == "deterministic" ? "deterministic" : "ai",
          provider: ai_request&.provider,
          model: ai_request&.model,
          response_id: ai_request&.response_id,
          input_tokens: ai_request&.input_tokens.to_i,
          output_tokens: ai_request&.output_tokens.to_i,
          total_tokens: ai_request&.total_tokens.to_i,
          attempt_count: ai_request&.attempt_count.to_i,
          failure_code: ai_request&.failure_code || ranking_metadata["fallback_reason"],
          recommended_for: extracted_context.recommended_for,
          completed_at: Time.current
        )
      end

      def fail_recommendation_request!(recommendation_request, error)
        return if recommendation_request.blank? || !recommendation_request.processing?

        recommendation_request.update_columns(
          status: "failed",
          failure_code: error.class.name.demodulize.underscore,
          completed_at: Time.current,
          updated_at: Time.current
        )
      end
    end
  end
end
