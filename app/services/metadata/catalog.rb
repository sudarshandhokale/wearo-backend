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
        preppy: "Preppy"
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
        style_profile: serialize_options(STYLE_OPTIONS)
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
