module Accounts
  class Export
    FORMAT_VERSION = "1.0"

    class << self
      def call(user:)
        {
          format_version: FORMAT_VERSION,
          exported_at: Time.current.iso8601,
          profile: User::ProfileSerializer.new(user).serializable_hash,
          style_profile: StyleProfile::ViewSerializer.new(user.style_profile).serializable_hash,
          clothing_items: clothing_items(user),
          outfits: outfits(user),
          wear_history: records(user.wear_histories.recent_first),
          outfit_feedback: records(user.outfit_feedbacks.order(:created_at)),
          recommendation_requests: recommendation_requests(user),
          styling_plans: styling_plans(user),
          styling_routines: user.styling_routines.order(:created_at).map { |routine| StylingRoutine::ViewSerializer.new(routine).serializable_hash },
          routine_occurrences: user.routine_occurrences.includes(:styling_routine, outfit: Outfit.cover_media_includes).order(:scheduled_for)
                                   .map { |occurrence| RoutineOccurrence::ViewSerializer.new(occurrence).serializable_hash },
          ai_requests: ai_requests(user)
        }
      end

      private

      def clothing_items(user)
        user.clothing_items.includes(image_attachment: :blob, polished_image_attachment: :blob).order(:created_at).map do |item|
          ClothingItem::ViewSerializer.new(item).serializable_hash
        end
      end

      def outfits(user)
        user.outfits.includes(Outfit.cover_media_includes).order(:created_at).map do |outfit|
          Outfit::ViewSerializer.new(outfit).serializable_hash
        end
      end

      def recommendation_requests(user)
        user.recommendation_requests.order(:created_at).as_json(
          except: %w[user_id],
          methods: []
        )
      end

      def styling_plans(user)
        user.styling_plans.includes(entries: { outfit: Outfit.cover_media_includes })
            .order(:created_at).map { |plan| StylingPlan::ViewSerializer.new(plan).serializable_hash }
      end

      def ai_requests(user)
        user.ai_requests.order(:created_at).as_json(
          only: %w[operation status provider model input_tokens output_tokens total_tokens attempt_count failure_code completed_at created_at]
        )
      end

      def records(scope)
        scope.as_json(except: %w[user_id updated_at])
      end
    end
  end
end
