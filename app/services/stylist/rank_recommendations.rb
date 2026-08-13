require "set"

module Stylist
  class RankRecommendations
    CANDIDATE_LIMIT = 30
    RECOMMENDATION_LIMIT = 3

    class << self
      def call(scored_combinations:, context:, user:, recommendation_request:, provider: Providers::Openai.new)
        candidates = scored_combinations.sort_by { |combination| -combination.score }.first(CANDIDATE_LIMIT)
        return [] if candidates.empty?

        ai_request = Ai::UsageTracker.start!(
          user: user,
          operation: "stylist_recommendation",
          trackable: recommendation_request,
          reserved_tokens: 3_000
        )
        provider_result = provider.call(
          context: context,
          candidates: serialize_candidates(candidates),
          user_id: user.id
        )
        ranked = build_ranked_combinations(candidates, provider_result, context)
        Ai::UsageTracker.succeed!(ai_request, provider_result.fetch(:metadata, {}))
        ranked
      rescue Ai::UsageLimitExceededError
        deterministic_ranking(candidates, context, reason: "usage_limit")
      rescue Ai::GuardrailViolationError => error
        Ai::UsageTracker.fail!(ai_request, error)
        deterministic_ranking(candidates, context, reason: "guardrail_violation")
      rescue ConfigurationError, ProviderError, InvalidRankingError, KeyError => error
        Ai::UsageTracker.fail!(ai_request, error)
        deterministic_ranking(candidates, context, reason: error.class.name.demodulize.underscore)
      end

      private

      def serialize_candidates(candidates)
        candidates.each_with_index.map do |candidate, index|
          {
            candidate_id: index + 1,
            score: candidate.score,
            score_breakdown: candidate.score_breakdown,
            items: candidate.items.map do |role, item|
              {
                role: role,
                clothing_item_id: item.id,
                category: item.category,
                subcategory: item.subcategory,
                primary_color: item.primary_color,
                occasion_tags: Ai::Guardrails.token_list!(item.occasion_tags),
                usage_tags: Ai::Guardrails.token_list!(item.effective_usage_tags),
                style_tags: Ai::Guardrails.token_list!(item.style_tags),
                cultural_tags: Ai::Guardrails.token_list!(item.cultural_tags),
                fit: item.fit,
                formality_score: item.formality_score
              }
            end
          }
        end
      end

      def build_ranked_combinations(candidates, provider_result, context)
        rankings = provider_result.fetch(:rankings)
        metadata = provider_result.fetch(:metadata, {})
        raise InvalidRankingError unless rankings.is_a?(Array)

        seen_ids = Set.new
        ranked = rankings.filter_map do |ranking|
          candidate_id = Integer(ranking["candidate_id"], exception: false)
          next if candidate_id.blank? || candidate_id > candidates.length || candidate_id < 1 || seen_ids.include?(candidate_id)

          explanation = Ai::Guardrails.model_text!(ranking["explanation"], max_length: 300)
          name = Ai::Guardrails.model_text!(ranking["name"], max_length: 60)

          seen_ids << candidate_id
          ranked_combination(candidates[candidate_id - 1], name, explanation, metadata)
        end.first(RECOMMENDATION_LIMIT)

        raise InvalidRankingError if ranked.empty?

        fill_with_deterministic_candidates(ranked, candidates, seen_ids, metadata, context)
      rescue KeyError, TypeError
        raise InvalidRankingError
      end

      def fill_with_deterministic_candidates(ranked, candidates, seen_ids, metadata, context)
        candidates.each_with_index do |candidate, index|
          break if ranked.length == RECOMMENDATION_LIMIT
          next if seen_ids.include?(index + 1)

          ranked << deterministic_combination(candidate, context, metadata)
        end
        ranked
      end

      def deterministic_ranking(candidates, context, reason: nil)
        Array(candidates).first(RECOMMENDATION_LIMIT).map do |candidate|
          deterministic_combination(
            candidate,
            context,
            { "provider" => "deterministic", "fallback_reason" => reason }.compact
          )
        end
      end

      def deterministic_combination(candidate, context, metadata)
        ranked_combination(
          candidate,
          OutfitName.call(items: candidate.items, occasion: context["occasion"]),
          fallback_explanation(context["occasion"]),
          metadata
        )
      end

      def ranked_combination(candidate, name, explanation, metadata)
        RankedCombination.new(
          items: candidate.items,
          score: candidate.score,
          score_breakdown: candidate.score_breakdown,
          name: name,
          explanation: explanation,
          ranking_metadata: metadata
        )
      end

      def fallback_explanation(occasion)
        I18n.t("stylist.fallback_explanation", occasion: occasion.presence || I18n.t("stylist.general_occasion"))
      end
    end
  end
end
