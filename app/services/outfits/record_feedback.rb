module Outfits
  class RecordFeedback
    class << self
      def call(user:, outfit:, attributes:)
        feedback = user.outfit_feedbacks.find_or_initialize_by(outfit: outfit)

        OutfitFeedback.transaction do
          feedback.update!(attributes)
          outfit.update!(
            rating: feedback.liked? ? 5 : 1,
            feedback_note: feedback.notes,
            status: feedback.disliked? ? :dismissed : liked_status(outfit),
            status_updated_at: Time.current
          )
          Personalization::RebuildProfile.call(user: user)
        end
        feedback
      end

      private

      def liked_status(outfit)
        outfit.worn? ? :worn : :saved
      end
    end
  end
end
