module ClothingAnalysis
  class NormalizeResult
    CATEGORY_ALIASES = {
      "tops" => "top",
      "upper_body" => "top",
      "bottoms" => "bottom",
      "pants" => "bottom",
      "outer_wear" => "outerwear",
      "shoe" => "shoes",
      "footwear" => "shoes",
      "accessories" => "accessory"
    }.freeze
    SUBCATEGORY_ALIASES = {
      "tee" => "t_shirt",
      "tshirt" => "t_shirt",
      "t_shirt" => "t_shirt",
      "trainer" => "sneakers",
      "trainers" => "sneakers",
      "sneaker" => "sneakers"
    }.freeze
    COLOR_ALIASES = {
      "dark_blue" => "navy",
      "navy_blue" => "navy",
      "light_blue" => "sky_blue",
      "grey" => "gray"
    }.freeze

    class << self
      def call(result)
        source = result.to_h.deep_stringify_keys
        category, subcategory = normalize_taxonomy(source)

        {
          "name" => normalize_name(source["name"]),
          "category" => category,
          "subcategory" => subcategory,
          "primary_color" => normalize_color(source["primary_color"]),
          "secondary_colors" => normalize_list(source["secondary_colors"], method(:normalize_color)),
          "pattern" => normalize_token(source["pattern"]),
          "material" => normalize_token(source["material"]),
          "season_tags" => normalize_list(source["season_tags"]),
          "occasion_tags" => normalize_list(source["occasion_tags"]),
          "style_tags" => normalize_list(source["style_tags"]),
          "formality_score" => normalize_integer(source["formality_score"]),
          "confidence" => normalize_number(source["confidence"])
        }
      rescue NoMethodError, TypeError
        raise InvalidResultError, "Analysis result must be an object"
      end

      private

      def normalize_taxonomy(source)
        category_token = normalize_token(source["category"])
        subcategory_token = normalize_subcategory(source["subcategory"])

        if subcategory_token.blank? && ClothingTaxonomy.subcategory_keys.include?(normalize_subcategory(category_token))
          subcategory_token = normalize_subcategory(category_token)
          category_token = nil
        end

        category = CATEGORY_ALIASES.fetch(category_token, category_token)
        category ||= category_for(subcategory_token)
        [ category, subcategory_token ]
      end

      def category_for(subcategory)
        ClothingTaxonomy.category_keys.find do |category|
          ClothingTaxonomy.subcategory_keys(category).include?(subcategory)
        end
      end

      def normalize_subcategory(value)
        token = normalize_token(value)
        SUBCATEGORY_ALIASES.fetch(token, token)
      end

      def normalize_name(value)
        value.to_s.strip.presence
      end

      def normalize_color(value)
        token = normalize_token(value)
        COLOR_ALIASES.fetch(token, token)
      end

      def normalize_list(value, normalizer = method(:normalize_token))
        Array(value).filter_map { |item| normalizer.call(item) }.uniq
      end

      def normalize_token(value)
        value.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "").presence
      end

      def normalize_integer(value)
        Integer(value, exception: false)
      end

      def normalize_number(value)
        Float(value, exception: false)
      end
    end
  end
end
