require "digest"

module Visualization
  class SourceFingerprint
    class << self
      def call(visualization)
        sources = visualization.outfit.outfit_items
                               .includes(clothing_item: { image_attachment: :blob })
                               .order(:position)
                               .filter_map do |outfit_item|
          image = outfit_item.clothing_item.image
          [ outfit_item.clothing_item_id, image.blob.checksum ] if image.attached?
        end

        payload = { mode: visualization.mode, garments: sources }
        if visualization.try_on?
          payload[:person_reference] = visualization.person_reference_image.blob.checksum
        end

        Digest::SHA256.hexdigest(payload.to_json)
      end
    end
  end
end
