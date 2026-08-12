module Outfits
  class MarkWorn
    class << self
      def call(user:, outfit:, worn_on:, occasion: nil, context: {})
        date = Date.iso8601(worn_on.to_s)
        history = user.wear_histories.find_or_initialize_by(outfit: outfit, worn_on: date)
        history.assign_attributes(occasion: occasion.presence || outfit.occasion, context: context.to_h)

        WearHistory.transaction do
          history.save!
          outfit.update!(status: :worn, status_updated_at: Time.current)
        end
        history
      rescue Date::Error
        raise ActiveRecord::RecordInvalid.new(user.wear_histories.new.tap { |record| record.errors.add(:worn_on, :invalid) })
      end
    end
  end
end
