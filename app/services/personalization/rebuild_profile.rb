module Personalization
  class RebuildProfile
    MINIMUM_SIGNAL = 1

    class << self
      def call(user:)
        profile = user.style_profile
        return if profile.blank?

        scores = aggregate_scores(user.outfit_feedbacks.includes(outfit: :clothing_items))
        learned = {
          "preferred_colors" => positive_keys(scores[:colors]),
          "disliked_colors" => negative_keys(scores[:colors]),
          "preferred_styles" => positive_keys(scores[:styles]),
          "disliked_styles" => negative_keys(scores[:styles]),
          "feedback_count" => user.outfit_feedbacks.count
        }

        profile.update!(additional_preferences: profile.additional_preferences.merge("learned" => learned))
      end

      private

      def aggregate_scores(feedbacks)
        feedbacks.each_with_object({ colors: Hash.new(0), styles: Hash.new(0) }) do |feedback, scores|
          weight = feedback.liked? ? 1 : -1
          feedback.outfit.clothing_items.each do |item|
            scores[:colors][item.primary_color] += weight if item.primary_color.present?
            item.style_tags.each { |style| scores[:styles][style] += weight }
          end
        end
      end

      def positive_keys(scores)
        scores.select { |_key, value| value >= MINIMUM_SIGNAL }.sort_by { |key, value| [ -value, key ] }.map(&:first).first(10)
      end

      def negative_keys(scores)
        scores.select { |_key, value| value <= -MINIMUM_SIGNAL }.sort_by { |key, value| [ value, key ] }.map(&:first).first(10)
      end
    end
  end
end
