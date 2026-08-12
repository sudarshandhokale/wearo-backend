class OutfitTaxonomy
  ROLES = {
    top: "Top",
    bottom: "Bottom",
    shoes: "Shoes",
    outerwear: "Outerwear",
    accessory: "Accessory"
  }.freeze

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

    def roles_for_metadata
      serialize_options(ROLES)
    end

    def statuses_for_metadata
      serialize_options(STATUSES)
    end

    private

    def serialize_options(options)
      options.map { |key, label| { key: key.to_s, label: label } }
    end
  end
end
