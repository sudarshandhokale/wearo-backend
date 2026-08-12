module Metadata
  class Catalog
    STYLE_OPTIONS = {
      preferred_styles: {
        minimal: "Minimal",
        classic: "Classic",
        streetwear: "Streetwear",
        athleisure: "Athleisure",
        smart_casual: "Smart Casual",
        business_casual: "Business Casual",
        bohemian: "Bohemian",
        edgy: "Edgy",
        preppy: "Preppy",
        traditional_indian: "Traditional Indian",
        ethnic: "Ethnic",
        indo_western: "Indo-Western",
        festive: "Festive"
      },
      preferred_colors: {
        black: "Black",
        white: "White",
        gray: "Gray",
        navy: "Navy",
        blue: "Blue",
        brown: "Brown",
        beige: "Beige",
        green: "Green",
        red: "Red",
        pink: "Pink",
        purple: "Purple"
      },
      disliked_colors: {
        black: "Black",
        white: "White",
        gray: "Gray",
        navy: "Navy",
        blue: "Blue",
        brown: "Brown",
        beige: "Beige",
        green: "Green",
        red: "Red",
        pink: "Pink",
        purple: "Purple",
        orange: "Orange",
        yellow: "Yellow",
        neon: "Neon"
      },
      fit_preferences: {
        tops: {
          slim: "Slim",
          regular: "Regular",
          relaxed: "Relaxed",
          oversized: "Oversized"
        },
        bottoms: {
          skinny: "Skinny",
          slim: "Slim",
          straight: "Straight",
          relaxed: "Relaxed",
          wide: "Wide"
        },
        shoes: {
          minimal: "Minimal",
          statement: "Statement",
          comfortable: "Comfortable"
        },
        outerwear: {
          fitted: "Fitted",
          regular: "Regular",
          relaxed: "Relaxed"
        }
      },
      occasions: {
        casual: "Casual",
        smart_casual: "Smart Casual",
        work: "Work",
        dinner: "Dinner",
        date_night: "Date Night",
        party: "Party",
        concert: "Concert",
        wedding: "Wedding",
        festival: "Festival",
        religious_ceremony: "Religious Ceremony",
        family_function: "Family Function",
        travel: "Travel",
        workout: "Workout",
        outdoor: "Outdoor"
      },
      seasons: {
        spring: "Spring",
        summer: "Summer",
        fall: "Fall",
        winter: "Winter",
        all_season: "All Season"
      }
    }.freeze

    def self.all
      {
        countries: countries,
        legal: legal,
        timezones: timezones,
        timezone_countries: timezone_countries,
        style_profile: serialize_options(STYLE_OPTIONS),
        clothing_items: {
          categories: ClothingTaxonomy.categories_for_metadata,
          fits: ClothingTaxonomy.fits_for_metadata,
          statuses: ClothingTaxonomy.statuses_for_metadata
        },
        outfits: {
          roles: OutfitTaxonomy.roles_for_metadata,
          base_compositions: OutfitTaxonomy.base_compositions_for_metadata,
          statuses: OutfitTaxonomy.statuses_for_metadata
        }
      }
    end

    def self.countries
      ISO3166::Country.all.map do |country|
        {
          code: country.alpha2,
          name: country.iso_short_name
        }
      end.sort_by { |country| country[:name] }
    end

    def self.legal
      {
        minimum_age: 18,
        terms: {
          version: User::TERMS_VERSION,
          url: AppConfig.fetch(:terms_url, default: "http://localhost:8081/terms")
        },
        privacy: {
          version: User::PRIVACY_VERSION,
          url: AppConfig.fetch(:privacy_url, default: "http://localhost:8081/privacy")
        },
        ai_processing_required: true,
        full_body_image_consent_required: true
      }
    end

    def self.timezones
      TZInfo::Timezone.all_identifiers.map do |identifier|
        { key: identifier, label: identifier.tr("_", " ") }
      end
    end

    def self.timezone_countries
      TZInfo::Country.all.each_with_object({}) do |country, mapping|
        country.zone_identifiers.each { |identifier| mapping[identifier] ||= country.code }
      end
    end

    def self.serialize_options(options)
      options.transform_values do |value|
        case value
        when Hash
          if value.values.all? { |nested_value| nested_value.is_a?(String) }
            value.map { |key, label| { key: key.to_s, label: label } }
          else
            serialize_options(value)
          end
        else
          value
        end
      end
    end
  end
end
