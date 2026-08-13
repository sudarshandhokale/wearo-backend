class ClothingUsageTaxonomy
  OPTIONS = %w[
    everyday home errands walking workout work travel outdoor social event special_occasion
  ].freeze

  class << self
    def keys
      OPTIONS
    end

    def for_metadata
      OPTIONS.map do |key|
        { key: key, label: Metadata::Labels.for(key, scope: :clothing_usage) }
      end
    end

    def suitable?(tags, context)
      normalized_tags = Array(tags)
      usage = context["usage"]
      normalized_tags.empty? || usage.blank? || normalized_tags.include?(usage)
    end

    def score(tags, context)
      normalized_tags = Array(tags)
      usage = context["usage"]
      return 70.0 if normalized_tags.empty? || usage.blank?

      normalized_tags.include?(usage) ? 100.0 : 35.0
    end
  end
end
