module Accounts
  class Erase
    CONFIRMATION_PHRASE = "DELETE"

    class << self
      def call(user:, password:, confirmation:)
        raise InvalidPasswordError unless user.valid_password?(password)
        raise InvalidDeletionConfirmationError unless confirmation == CONFIRMATION_PHRASE

        erase_records!(user)
      end

      def erase_unverified!(user)
        raise InvalidDeletionConfirmationError if user.confirmed?

        erase_records!(user)
      end

      private

      def erase_records!(user)
        User.transaction do
          user.styling_plans.destroy_all
          user.outfit_visualizations.destroy_all
          user.outfit_feedbacks.destroy_all
          user.wear_histories.destroy_all
          user.outfits.destroy_all
          user.recommendation_requests.destroy_all
          user.clothing_items.destroy_all
          user.wardrobe&.destroy!
          user.ai_requests.destroy_all
          user.style_profile&.destroy!
          user.destroy!
        end
      end
    end
  end
end
