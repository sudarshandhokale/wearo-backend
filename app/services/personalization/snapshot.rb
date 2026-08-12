module Personalization
  class Snapshot
    LOOKBACK_DAYS = 90

    class << self
      def call(user:, as_of: Time.current.to_date)
        histories = user.wear_histories
                        .where(worn_on: (as_of - LOOKBACK_DAYS.days)..as_of)
                        .includes(outfit: :outfit_items)

        {
          "last_worn_by_item_id" => last_worn_by_item_id(histories),
          "learned" => user.style_profile&.additional_preferences.to_h.fetch("learned", {})
        }
      end

      private

      def last_worn_by_item_id(histories)
        histories.each_with_object({}) do |history, result|
          history.outfit.outfit_items.each do |outfit_item|
            item_id = outfit_item.clothing_item_id.to_s
            current = result[item_id]
            result[item_id] = history.worn_on.iso8601 if current.blank? || history.worn_on > Date.iso8601(current)
          end
        end
      end
    end
  end
end
