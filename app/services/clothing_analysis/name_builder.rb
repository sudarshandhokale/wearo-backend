module ClothingAnalysis
  class NameBuilder
    NON_DESCRIPTIVE_PATTERNS = %w[solid plain].freeze

    class << self
      def call(proposed_name:, attributes:)
        proposed_name = proposed_name.to_s.squish.presence
        return proposed_name if meaningful?(proposed_name, attributes)

        build_name(attributes).presence || proposed_name
      end

      private

      def meaningful?(name, attributes)
        return false if name.blank? || name.scan(/[[:alnum:]]+/).length < 2

        canonical_name = canonical(name)
        visual_descriptors(attributes).any? { |descriptor| canonical_name.include?(canonical(descriptor)) }
      end

      def build_name(attributes)
        base = attributes["garment_type"].presence ||
               ClothingTaxonomy.subcategory_label(attributes["category"], attributes["subcategory"]) ||
               ClothingTaxonomy.category_label(attributes["category"])
        return if base.blank?

        parts = visual_descriptors(attributes)
          .reject { |value| canonical(base).include?(canonical(value)) }
          .map { |value| display(value) }
        parts << base
        parts.compact_blank.uniq { |value| canonical(value) }.join(" ").truncate(120, omission: "")
      end

      def visual_descriptors(attributes)
        values = [ attributes["primary_color"] ]
        values.concat(Array(attributes["secondary_colors"]).first(1)) if descriptive_pattern?(attributes["pattern"])
        values << attributes["pattern"] if descriptive_pattern?(attributes["pattern"])
        values << attributes["material"]
        values << attributes["fit"] if values.compact_blank.empty?
        values.compact_blank.uniq
      end

      def descriptive_pattern?(pattern)
        pattern.present? && NON_DESCRIPTIVE_PATTERNS.exclude?(pattern)
      end

      def display(value)
        value.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
      end

      def canonical(value)
        value.to_s.downcase.gsub(/[^[:alnum:]]/, "")
      end
    end
  end
end
