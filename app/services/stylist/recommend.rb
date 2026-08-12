module Stylist
  class Recommend
    DEFAULT_DAILY_RECOMMENDATION_LIMIT = 50

    class << self
      def call(user:, prompt:)
        prompt = Ai::Guardrails.user_prompt!(prompt.to_s)
        recommendation_request = create_recommendation_request!(user, prompt)
        extracted_context = ExtractContext.call(prompt, timezone: user.timezone)
        external_context = fetch_external_context(user, extracted_context)
        recommendation_context = enriched_context(extracted_context.attributes, external_context)
        personalization = Personalization::Snapshot.call(user: user, as_of: extracted_context.recommended_for&.to_date || Time.current.to_date)
        candidates = CandidateSelector.call(user: user, context: recommendation_context)
        combinations = CombinationBuilder.call(candidates: candidates, context: recommendation_context)
        scored_combinations = combinations.map do |combination|
          CompatibilityScorer.call(
            combination: combination,
            context: recommendation_context,
            style_profile: user.style_profile,
            personalization: personalization
          )
        end
        ranked_combinations = RankRecommendations.call(
          scored_combinations: scored_combinations,
          context: recommendation_context,
          user: user,
          recommendation_request: recommendation_request
        )

        outfits = persist_outfits(
          user: user,
          recommendation_request: recommendation_request,
          prompt: prompt,
          extracted_context: extracted_context,
          context: recommendation_context,
          weather: external_context.weather,
          ranked_combinations: ranked_combinations
        )
        suggestions = WardrobeSuggestions.call(
          candidates: candidates,
          context: recommendation_context,
          user: user,
          selected_item_ids: outfits.first&.clothing_item_ids || []
        )
        complete_recommendation_request!(
          recommendation_request,
          extracted_context: extracted_context,
          context: recommendation_context,
          suggestions: suggestions,
          ranked_combinations: ranked_combinations
        )

        RecommendationResult.new(
          recommendation_request: recommendation_request,
          context: recommendation_context,
          outfits: outfits,
          suggestions: suggestions
        )
      rescue Ai::GuardrailViolationError
        fail_recommendation_request!(recommendation_request, InvalidPromptError.new)
        raise InvalidPromptError
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

      def persist_outfits(user:, recommendation_request:, prompt:, extracted_context:, context:, weather:, ranked_combinations:)
        Outfit.transaction do
          ranked_combinations.map do |ranked_combination|
            outfit = user.outfits.create!(
              recommendation_request: recommendation_request,
              prompt: prompt,
              occasion: extracted_context.attributes["occasion"],
              context: context,
              weather_context: Array(weather).find { |day| day["date"] == extracted_context.recommended_for&.to_date&.iso8601 } || Array(weather).first || {},
              name: ranked_combination.name,
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

      def complete_recommendation_request!(recommendation_request, extracted_context:, context:, suggestions:, ranked_combinations:)
        ranking_metadata = ranked_combinations.first&.ranking_metadata.to_h.stringify_keys
        ai_request = recommendation_request.ai_requests.order(created_at: :desc).first

        recommendation_request.update!(
          status: :completed,
          context: context,
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

      def fetch_external_context(user, extracted_context)
        date = extracted_context.recommended_for&.to_date || Time.current.in_time_zone(user.timezone).to_date
        ExternalContext::Fetch.call(
          user: user,
          city: extracted_context.city,
          start_date: date,
          end_date: date
        )
      end

      def enriched_context(context, external_context)
        weather = external_context.weather.first
        context.merge(
          "city" => external_context.city,
          "weather" => weather
        ).compact
      end
    end
  end
end
