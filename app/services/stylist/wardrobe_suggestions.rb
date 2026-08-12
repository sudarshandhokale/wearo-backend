module Stylist
  class WardrobeSuggestions
    MAX_SUGGESTIONS = 3
    OPTIONAL_ROLES = %w[shoes accessory].freeze
    PRIORITIES = { "essential" => 0, "recommended" => 1, "optional" => 2 }.freeze
    TYPE_ORDER = { "weather" => 0, "styling" => 1, "wardrobe" => 2 }.freeze
    STYLING_OPTIONS = {
      "wedding" => %w[jewelry bangles clutch dupatta stole bindi],
      "festival" => %w[jewelry bangles dupatta stole bindi],
      "religious_ceremony" => %w[dupatta stole jewelry bangles],
      "family_function" => %w[jewelry bangles bag clutch],
      "date_night" => %w[bag clutch jewelry watch],
      "dinner" => %w[bag clutch jewelry watch],
      "party" => %w[clutch jewelry bag watch],
      "work" => %w[bag tote watch belt]
    }.freeze
    BASE_ROLES = OutfitTaxonomy.base_combinations.flatten.uniq.freeze

    class << self
      def call(candidates:, context:, user: nil, selected_item_ids: [])
        suggestions = weather_suggestions(candidates, context, selected_item_ids)
        suggestions.concat(missing_optional_suggestions(candidates, context))
        suggestions << missing_outerwear_suggestion(candidates, context)
        suggestions << styling_suggestion(candidates, context, selected_item_ids)
        suggestions << wardrobe_variety_suggestion(candidates, user)

        suggestions.compact
                   .uniq { |item| item[:key] }
                   .sort_by { |item| [ PRIORITIES.fetch(item[:priority], 3), TYPE_ORDER.fetch(item[:type], 3) ] }
                   .first(MAX_SUGGESTIONS)
      end

      private

      def weather_suggestions(candidates, context, selected_item_ids)
        weather = context["weather"].to_h
        return [] unless rainy?(weather)

        rain_item = find_item(candidates, %w[umbrella raincoat waterproof water_resistant])
        return [ owned_item_suggestion(rain_item, "rain", "weather") ] if rain_item.present? && selected_item_ids.exclude?(rain_item.id)
        return [] if rain_item.present?

        [
          build_suggestion(
            key: "bring_rain_protection",
            type: "weather",
            priority: "essential",
            action: "bring",
            role: "accessory",
            suggested_subcategories: %w[umbrella raincoat water_resistant_shoes]
          )
        ]
      end

      def missing_optional_suggestions(candidates, context)
        OPTIONAL_ROLES.filter_map do |role|
          next unless candidates.fetch(role).empty?

          options = role == "accessory" ? styling_options(context) : []
          build_suggestion(
            key: "add_#{role}",
            type: role == "accessory" ? "styling" : "wardrobe",
            priority: "optional",
            action: "add_to_wardrobe",
            role: role,
            suggested_subcategories: options
          )
        end
      end

      def missing_outerwear_suggestion(candidates, context)
        return unless outerwear_relevant?(context) && candidates.fetch("outerwear").empty?

        build_suggestion(
          key: "add_outerwear",
          type: "weather",
          priority: cold?(context["weather"].to_h) ? "essential" : "recommended",
          action: "add_to_wardrobe",
          role: "outerwear",
          suggested_subcategories: cold?(context["weather"].to_h) ? %w[coat jacket cardigan] : %w[raincoat jacket]
        )
      end

      def styling_suggestion(candidates, context, selected_item_ids)
        options = styling_options(context)
        return if options.empty?

        item = find_item({ "accessory" => candidates.fetch("accessory") }, options, roles: [ "accessory" ], excluding: selected_item_ids)
        return owned_item_suggestion(item, "finishing_touch", "styling") if item.present?
        return if candidates.fetch("accessory").empty?

        build_suggestion(
          key: "try_another_finishing_touch",
          type: "styling",
          priority: "optional",
          action: "consider",
          role: "accessory",
          suggested_subcategories: options
        )
      end

      def wardrobe_variety_suggestion(candidates, user)
        return if user.blank?

        core_items = BASE_ROLES.flat_map { |role| candidates.fetch(role, []) }.uniq
        return if core_items.length >= 5

        build_suggestion(
          key: "expand_core_wardrobe",
          type: "wardrobe",
          priority: "recommended",
          action: "add_to_wardrobe",
          role: "core",
          count: core_items.length,
          suggested_subcategories: versatile_subcategories(candidates)
        )
      end

      def versatile_subcategories(candidates)
        return %w[t_shirt shirt blouse kurta] if candidates.fetch("top", []).length < 2
        return %w[jeans trousers skirt palazzo] if candidates.fetch("bottom", []).length < 2
        return %w[dress jumpsuit abaya kaftan] if candidates.fetch("one_piece", []).length < 2

        %w[matching_set co_ord traditional_set]
      end

      def owned_item_suggestion(item, key, type)
        build_suggestion(
          key: "use_owned_#{key}",
          type: type,
          priority: type == "weather" ? "essential" : "optional",
          action: "use_owned_item",
          role: item.category,
          clothing_item_id: item.id,
          item_name: item.name.presence || item.subcategory.to_s.humanize,
          suggested_subcategories: [ item.subcategory ].compact
        )
      end

      def build_suggestion(key:, type:, priority:, action:, role:, suggested_subcategories:, clothing_item_id: nil, item_name: nil, count: nil)
        interpolation = { item_name: item_name, count: count }.compact
        {
          key: key,
          type: type,
          priority: priority,
          action: action,
          role: role,
          clothing_item_id: clothing_item_id,
          suggested_subcategories: suggested_subcategories,
          message: I18n.t("stylist.suggestions.#{key}.message", **interpolation),
          question: I18n.t("stylist.suggestions.#{key}.question", **interpolation)
        }.compact
      end

      def find_item(candidates, tokens, roles: %w[accessory outerwear shoes], excluding: [])
        roles.flat_map { |role| candidates.fetch(role, []) }.find do |item|
          excluding.exclude?(item.id) && ([ item.subcategory, item.garment_type ] + item.style_tags).compact.intersect?(tokens)
        end
      end

      def styling_options(context)
        STYLING_OPTIONS.fetch(context["occasion"], [])
      end

      def rainy?(weather)
        weather["condition"].in?(%w[rain storm mixed]) || weather["precipitation_probability"].to_i >= 50
      end

      def cold?(weather)
        weather["apparent_temperature_min_c"].present? && weather["apparent_temperature_min_c"].to_f < 10
      end

      def outerwear_relevant?(context)
        context["season"].in?(%w[fall winter]) || context["formality"] == "formal" || cold?(context["weather"].to_h) || rainy?(context["weather"].to_h)
      end
    end
  end
end
