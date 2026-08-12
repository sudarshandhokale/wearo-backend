class OutfitTaxonomy
  ROLES = {
    top: "Top",
    bottom: "Bottom",
    one_piece: "One Piece",
    drape: "Drape",
    set: "Set",
    shoes: "Shoes",
    outerwear: "Outerwear",
    accessory: "Accessory"
  }.freeze

  BASE_COMPOSITIONS = {
    separates: {
      label: "Top and Bottom",
      roles: %w[top bottom]
    },
    one_piece: {
      label: "One Piece",
      roles: %w[one_piece]
    },
    drape: {
      label: "Drape and Top",
      roles: %w[drape top]
    },
    set: {
      label: "Set",
      roles: %w[set]
    }
  }.freeze

  OPTIONAL_ROLES = %w[shoes outerwear accessory].freeze

  STATUSES = {
    recommended: "Recommended",
    worn: "Worn",
    dismissed: "Dismissed"
  }.freeze

  class << self
    def role_keys
      ROLES.keys.map(&:to_s)
    end

    def status_keys
      STATUSES.keys.map(&:to_s)
    end

    def base_combinations
      BASE_COMPOSITIONS.values.map { |composition| composition[:roles] }
    end

    def optional_role_keys
      OPTIONAL_ROLES
    end

    def roles_for_metadata
      serialize_options(ROLES)
    end

    def statuses_for_metadata
      serialize_options(STATUSES)
    end

    def base_compositions_for_metadata
      BASE_COMPOSITIONS.map do |key, composition|
        {
          key: key.to_s,
          label: composition[:label],
          roles: composition[:roles]
        }
      end
    end

    private

    def serialize_options(options)
      options.map { |key, label| { key: key.to_s, label: label } }
    end
  end
end
