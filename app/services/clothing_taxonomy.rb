class ClothingTaxonomy
  CATEGORIES = {
    top: {
      label: "Top",
      subcategories: {
        t_shirt: "T-shirt",
        polo: "Polo",
        shirt: "Shirt",
        sweater: "Sweater",
        hoodie: "Hoodie"
      }
    },
    bottom: {
      label: "Bottom",
      subcategories: {
        jeans: "Jeans",
        trousers: "Trousers",
        chinos: "Chinos",
        shorts: "Shorts"
      }
    },
    outerwear: {
      label: "Outerwear",
      subcategories: {
        jacket: "Jacket",
        coat: "Coat"
      }
    },
    shoes: {
      label: "Shoes",
      subcategories: {
        sneakers: "Sneakers",
        boots: "Boots",
        loafers: "Loafers",
        sandals: "Sandals"
      }
    },
    accessory: {
      label: "Accessory",
      subcategories: {
        belt: "Belt",
        watch: "Watch",
        bag: "Bag",
        hat: "Hat",
        scarf: "Scarf"
      }
    }
  }.freeze

  STATUSES = {
    uploaded: "Uploaded",
    processing: "Processing",
    ready: "Ready",
    analysis_failed: "Analysis Failed"
  }.freeze

  class << self
    def category_keys
      CATEGORIES.keys.map(&:to_s)
    end

    def status_keys
      STATUSES.keys.map(&:to_s)
    end

    def subcategory_keys(category = nil)
      return CATEGORIES.values.flat_map { |value| value[:subcategories].keys }.map(&:to_s) if category.blank?

      CATEGORIES.dig(category.to_s.to_sym, :subcategories).to_h.keys.map(&:to_s)
    end

    def categories_for_metadata
      CATEGORIES.map do |key, config|
        {
          key: key.to_s,
          label: config[:label],
          subcategories: config[:subcategories].map { |subcategory_key, label| { key: subcategory_key.to_s, label: label } }
        }
      end
    end

    def statuses_for_metadata
      STATUSES.map { |key, label| { key: key.to_s, label: label } }
    end
  end
end
