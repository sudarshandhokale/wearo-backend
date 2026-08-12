module Stylist
  class OutfitName
    class << self
      def call(items:, occasion: nil)
        descriptor = Array(items).filter_map do |_role, item|
          [ item.primary_color, item.garment_type.presence || item.subcategory ].compact_blank.join(" ").presence
        end.first.to_s.titleize
        occasion_label = occasion.to_s.titleize.presence

        value = if descriptor.present? && occasion_label.present?
          I18n.t("stylist.outfit_names.with_occasion", descriptor: descriptor, occasion: occasion_label)
        elsif descriptor.present?
          I18n.t("stylist.outfit_names.without_occasion", descriptor: descriptor)
        elsif occasion_label.present?
          I18n.t("stylist.outfit_names.without_descriptor", occasion: occasion_label)
        else
          I18n.t("stylist.outfit_names.generic")
        end

        value.truncate(60, omission: "")
      end
    end
  end
end
