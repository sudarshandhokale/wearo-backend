module Stylist
  class CombinationBuilder
    MAX_COMBINATIONS = 1_000

    class << self
      def call(candidates:, context:)
        core_combinations = candidates.fetch("top").product(
          candidates.fetch("bottom"),
          candidates.fetch("shoes")
        ).first(MAX_COMBINATIONS)

        core_combinations.each_with_index.map do |(top, bottom, shoes), index|
          items = { "top" => top, "bottom" => bottom, "shoes" => shoes }
          add_optional_item(items, "outerwear", candidates, index) if outerwear_relevant?(context)
          add_optional_item(items, "accessory", candidates, index)
          Combination.new(items: items)
        end
      end

      private

      def add_optional_item(items, role, candidates, index)
        available_items = candidates.fetch(role, [])
        return if available_items.empty?

        items[role] = available_items[index % available_items.length]
      end

      def outerwear_relevant?(context)
        context["season"].in?(%w[fall winter]) || context["formality"] == "formal"
      end
    end
  end
end
