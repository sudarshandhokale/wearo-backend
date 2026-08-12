module ClothingAnalysis
  class NormalizeResult
    CATEGORY_ALIASES = {
      "tops" => "top",
      "upper_body" => "top",
      "bottoms" => "bottom",
      "pants" => "bottom",
      "dress" => "one_piece",
      "full_dress" => "one_piece",
      "jumpsuit" => "one_piece",
      "romper" => "one_piece",
      "onepiece" => "one_piece",
      "matching_set" => "set",
      "co_ord" => "set",
      "coord" => "set",
      "traditional_set" => "set",
      "sari_set" => "set",
      "kurta_set" => "set",
      "sherwani_set" => "set",
      "sari" => "drape",
      "saree" => "drape",
      "hanbok" => "set",
      "hanfu" => "set",
      "agbada" => "set",
      "kebaya" => "set",
      "abaya" => "one_piece",
      "kaftan" => "one_piece",
      "thobe" => "one_piece",
      "kimono" => "one_piece",
      "dashiki" => "top",
      "kilt" => "bottom",
      "sarong" => "drape",
      "wrapper" => "drape",
      "poncho" => "outerwear",
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
      "sneaker" => "sneakers",
      "coord" => "co_ord",
      "co_ords" => "co_ord",
      "pantsuit" => "suit",
      "sari" => "saree",
      "lehenga" => "lehenga_set",
      "salwar_kameez" => "salwar_suit",
      "kurta_pajama" => "kurta_set",
      "kurta_pyjama" => "kurta_set",
      "sherwani" => "sherwani",
      "mojri" => "mojari",
      "hanbok" => "hanbok_set",
      "hanfu" => "hanfu_set",
      "agbada" => "agbada_set",
      "kebaya" => "kebaya_set"
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
          "garment_type" => normalize_name(source["garment_type"]) || normalize_name(source["subcategory"]),
          "category" => category,
          "subcategory" => safe_subcategory(category, subcategory),
          "primary_color" => normalize_color(source["primary_color"]),
          "secondary_colors" => normalize_list(source["secondary_colors"], method(:normalize_color)),
          "pattern" => normalize_token(source["pattern"]),
          "material" => normalize_token(source["material"]),
          "season_tags" => normalize_list(source["season_tags"]),
          "occasion_tags" => normalize_list(source["occasion_tags"]),
          "style_tags" => normalize_list(source["style_tags"]),
          "cultural_tags" => normalize_list(source["cultural_tags"]),
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

        category_as_subcategory = normalize_subcategory(category_token)
        if ClothingTaxonomy.subcategory_keys.include?(category_as_subcategory)
          subcategory_token ||= category_as_subcategory
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

      def safe_subcategory(category, subcategory)
        return subcategory if ClothingTaxonomy.subcategory_keys(category).include?(subcategory)
        return subcategory if category_for(subcategory).present?
        return "other" if ClothingTaxonomy.category_keys.include?(category)

        subcategory
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
