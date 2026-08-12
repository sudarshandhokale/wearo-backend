module Stylist
  class CombinationBuilder
    MAX_COMBINATIONS = 1_000

    class << self
      def call(candidates:, context:)
        base_combinations = OutfitTaxonomy.base_combinations.flat_map do |roles|
          combinations_for_roles(candidates, roles)
        end

        base_combinations.first(MAX_COMBINATIONS).each_with_index.map do |items, index|
          add_optional_item(items, "shoes", candidates, index)
          add_optional_item(items, "outerwear", candidates, index) if outerwear_relevant?(context)
          add_optional_item(items, "accessory", candidates, index)
          Combination.new(items: items)
        end
      end

      private

      def combinations_for_roles(candidates, roles)
        roles.reduce([ {} ]) do |combinations, role|
          combinations.product(candidates.fetch(role)).map do |combination, clothing_item|
            combination.merge(role => clothing_item)
          end.first(MAX_COMBINATIONS)
        end
      end

      def add_optional_item(items, role, candidates, index)
        available_items = candidates.fetch(role, [])
        return if available_items.empty?

        items[role] = available_items[index % available_items.length]
      end

      def outerwear_relevant?(context)
        weather = context["weather"].to_h
        cold = weather["apparent_temperature_min_c"].present? && weather["apparent_temperature_min_c"].to_f < 10
        wet = weather["precipitation_probability"].present? && weather["precipitation_probability"].to_i >= 50
        context["season"].in?(%w[fall winter]) || context["formality"] == "formal" || cold || wet
      end
    end
  end
end
