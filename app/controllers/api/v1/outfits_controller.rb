module Api
  module V1
    class OutfitsController < BaseController
      def show
        outfit = current_user.outfits.includes(outfit_items: { clothing_item: { image_attachment: :blob } }).find(params[:id])
        success_response(data: outfit, serializer: Outfit::ViewSerializer)
      end
    end
  end
end
