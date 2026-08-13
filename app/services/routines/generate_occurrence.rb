module Routines
  class GenerateOccurrence
    class << self
      def call(occurrence)
        occurrence.with_lock do
          return occurrence unless occurrence.scheduled? || occurrence.queued?

          occurrence.update!(status: :generating)
        end

        combined_occurrence = combinable_next_occurrence(occurrence)
        routine = combined_occurrence&.styling_routine || occurrence.styling_routine
        context, weather = context_for(occurrence, routine)
        candidates = Stylist::CandidateSelector.call(user: occurrence.user, context: context)
        local_date = occurrence.scheduled_for.in_time_zone(occurrence.user.timezone).to_date
        personalization = Personalization::Snapshot.call(user: occurrence.user, as_of: local_date)
        selected = select_combination(occurrence.user, candidates, context, personalization)
        outfit = persist_outfit(occurrence, routine, context, weather, selected)
        suggestions = Stylist::WardrobeSuggestions.call(
          candidates: candidates, context: context, user: occurrence.user,
          selected_item_ids: selected.items.values.map(&:id)
        )
        complete!(occurrence, outfit, context, weather, suggestions)
        complete!(combined_occurrence, outfit, context.merge("combined" => true), weather, suggestions) if combined_occurrence
        occurrence
      rescue StandardError => error
        occurrence.update_columns(status: "failed", failure_code: failure_code(error), updated_at: Time.current) if occurrence&.persisted?
        raise
      end

      private

      def select_combination(user, candidates, context, personalization)
        selected = Stylist::CombinationBuilder.call(candidates: candidates, context: context).map do |combination|
          Stylist::CompatibilityScorer.call(
            combination: combination, context: context, style_profile: user.style_profile,
            personalization: personalization
          )
        end.max_by(&:score)
        return selected if selected

        raise Stylist::InsufficientWardrobeError.new([], required_combinations: OutfitTaxonomy.base_combinations)
      end

      def context_for(occurrence, routine)
        date = occurrence.scheduled_for.in_time_zone(occurrence.user.timezone).to_date
        external = ExternalContext::Fetch.call(
          user: occurrence.user, city: routine.city_for_context, start_date: date, end_date: date
        )
        weather = external.weather.first || {}
        context = {
          "occasion" => routine.occasion.presence || default_occasion(routine.routine_type),
          "formality" => routine.routine_type == "work" ? "smart_casual" : "casual",
          "activity" => routine.activity.presence || default_activity(routine.routine_type),
          "usage" => routine.usage,
          "city" => external.city,
          "weather" => weather,
          "routine_id" => routine.id,
          "routine_name" => routine.name
        }.compact
        [ context, weather ]
      end

      def persist_outfit(occurrence, routine, context, weather, selected)
        Outfit.transaction do
          outfit = occurrence.user.outfits.create!(
            prompt: I18n.t("routines.recommendation_prompt", routine: routine.name),
            occasion: context["occasion"], context: context, weather_context: weather,
            name: Stylist::OutfitName.call(items: selected.items, occasion: context["occasion"]),
            recommendation_score: selected.score, score_breakdown: selected.score_breakdown,
            explanation: I18n.t("routines.recommendation_explanation", routine: routine.name),
            status: :recommended, recommended_for: occurrence.scheduled_for
          )
          selected.items.each_with_index do |(role, item), position|
            outfit.outfit_items.create!(clothing_item: item, role: role, position: position)
          end
          outfit
        end
      end

      def complete!(occurrence, outfit, context, weather, suggestions)
        occurrence.update!(status: :generated, outfit: outfit, context: context, weather_context: weather,
                           suggestions: suggestions, generated_at: Time.current, failure_code: nil)
      end

      def combinable_next_occurrence(occurrence)
        return unless occurrence.styling_routine.outfit_strategy == "combine_with_next"

        occurrence.user.routine_occurrences.scheduled
                  .where(scheduled_for: (occurrence.scheduled_for + 1.minute)..(occurrence.scheduled_for + 4.hours))
                  .chronological.first
      end

      def default_occasion(type)
        { "work" => "work", "religious" => "religious_ceremony" }.fetch(type, "casual")
      end

      def default_activity(type)
        { "work" => "professional", "walking" => "walking", "workout" => "active", "social" => "social" }.fetch(type, "outdoor")
      end

      def failure_code(error)
        error.is_a?(Stylist::InsufficientWardrobeError) ? "insufficient_wardrobe" : "generation_failed"
      end
    end
  end
end
