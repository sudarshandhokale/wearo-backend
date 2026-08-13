class ClothingTaxonomy
  CATEGORIES = {
    top: {
      label: "Top",
      subcategories: {
        t_shirt: "T-shirt",
        polo: "Polo",
        shirt: "Shirt",
        blouse: "Blouse",
        tank_top: "Tank Top",
        crop_top: "Crop Top",
        camisole: "Camisole",
        bodysuit: "Bodysuit",
        tunic: "Tunic",
        kurta: "Kurta",
        kurti: "Kurti",
        choli: "Choli",
        ethnic_blouse: "Ethnic Blouse",
        sherwani: "Sherwani",
        dashiki: "Dashiki",
        sweater: "Sweater",
        hoodie: "Hoodie",
        other: "Other Top"
      }
    },
    bottom: {
      label: "Bottom",
      subcategories: {
        jeans: "Jeans",
        trousers: "Trousers",
        wide_leg_trousers: "Wide-Leg Trousers",
        chinos: "Chinos",
        shorts: "Shorts",
        skirt: "Skirt",
        leggings: "Leggings",
        joggers: "Joggers",
        cargo_pants: "Cargo Pants",
        salwar: "Salwar",
        churidar: "Churidar",
        pajama: "Pajama",
        dhoti: "Dhoti",
        palazzo: "Palazzo",
        lehenga_skirt: "Lehenga Skirt",
        kilt: "Kilt",
        other: "Other Bottom"
      }
    },
    one_piece: {
      label: "One Piece",
      subcategories: {
        dress: "Dress",
        midi_dress: "Midi Dress",
        maxi_dress: "Maxi Dress",
        gown: "Gown",
        jumpsuit: "Jumpsuit",
        romper: "Romper",
        overall: "Overall",
        swimsuit: "Swimsuit",
        abaya: "Abaya",
        kaftan: "Kaftan",
        thobe: "Thobe",
        kimono: "Kimono",
        other: "Other One Piece"
      }
    },
    drape: {
      label: "Drape",
      subcategories: {
        saree: "Saree",
        half_saree: "Half Saree",
        dhoti_drape: "Dhoti Drape",
        sarong: "Sarong",
        wrapper: "Wrapper",
        other: "Other Drape"
      }
    },
    set: {
      label: "Set",
      subcategories: {
        matching_set: "Matching Set",
        co_ord: "Co-ord",
        suit: "Suit",
        activewear_set: "Activewear Set",
        sleepwear_set: "Sleepwear Set",
        bikini_set: "Bikini Set",
        traditional_set: "Traditional Set",
        saree_set: "Saree Set",
        lehenga_set: "Lehenga Set",
        salwar_suit: "Salwar Suit",
        kurta_set: "Kurta Set",
        sherwani_set: "Sherwani Set",
        anarkali_set: "Anarkali Set",
        hanbok_set: "Hanbok Set",
        hanfu_set: "Hanfu Set",
        agbada_set: "Agbada Set",
        kebaya_set: "Kebaya Set",
        other: "Other Set"
      }
    },
    outerwear: {
      label: "Outerwear",
      subcategories: {
        jacket: "Jacket",
        coat: "Coat",
        blazer: "Blazer",
        cardigan: "Cardigan",
        vest: "Vest",
        trench_coat: "Trench Coat",
        raincoat: "Raincoat",
        poncho: "Poncho",
        cloak: "Cloak",
        other: "Other Outerwear"
      }
    },
    shoes: {
      label: "Shoes",
      subcategories: {
        sneakers: "Sneakers",
        boots: "Boots",
        loafers: "Loafers",
        sandals: "Sandals",
        heels: "Heels",
        pumps: "Pumps",
        flats: "Flats",
        mules: "Mules",
        wedges: "Wedges",
        jutti: "Jutti",
        mojari: "Mojari",
        kolhapuri: "Kolhapuri",
        other: "Other Shoes"
      }
    },
    accessory: {
      label: "Accessory",
      subcategories: {
        belt: "Belt",
        watch: "Watch",
        bag: "Bag",
        clutch: "Clutch",
        tote: "Tote",
        hat: "Hat",
        scarf: "Scarf",
        dupatta: "Dupatta",
        stole: "Stole",
        turban: "Turban",
        sunglasses: "Sunglasses",
        umbrella: "Umbrella",
        jewelry: "Jewelry",
        bangles: "Bangles",
        bindi: "Bindi",
        other: "Other Accessory"
      }
    }
  }.freeze

  STATUSES = {
    uploaded: "Uploaded",
    processing: "Processing",
    ready: "Ready",
    analysis_failed: "Analysis Failed"
  }.freeze
  FITS = {
    fitted: "Fitted",
    slim: "Slim",
    regular: "Regular",
    relaxed: "Relaxed",
    oversized: "Oversized",
    flowing: "Flowing",
    structured: "Structured"
  }.freeze

  class << self
    def category_keys
      CATEGORIES.keys.map(&:to_s)
    end

    def status_keys
      STATUSES.keys.map(&:to_s)
    end

    def fit_keys
      FITS.keys.map(&:to_s)
    end

    def fits_for_metadata
      FITS.map { |key, label| { key: key.to_s, label: label } }
    end

    def subcategory_keys(category = nil)
      return CATEGORIES.values.flat_map { |value| value[:subcategories].keys }.map(&:to_s) if category.blank?

      CATEGORIES.dig(category.to_s.to_sym, :subcategories).to_h.keys.map(&:to_s)
    end

    def category_label(category)
      CATEGORIES.dig(category.to_s.to_sym, :label)
    end

    def subcategory_label(category, subcategory)
      CATEGORIES.dig(category.to_s.to_sym, :subcategories, subcategory.to_s.to_sym)
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
