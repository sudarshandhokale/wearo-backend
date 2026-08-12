module Api
  module V1
    class OutfitsController < BaseController
      before_action :set_outfit, only: %i[show update]

      def index
        outfits = current_user.outfits
                              .recent_first
                              .includes(outfit_items: { clothing_item: { image_attachment: :blob } })
                              .page(params[:page])
                              .per(per_page)
        success_response(
          data: ActiveModelSerializers::SerializableResource.new(outfits, each_serializer: Outfit::ViewSerializer),
          meta: pagination_meta(outfits)
        )
      end

      def show
        success_response(data: @outfit, serializer: Outfit::ViewSerializer)
      end

      def update
        attributes = outfit_params
        attributes[:status_updated_at] = Time.current if attributes.key?(:status) && attributes[:status] != @outfit.status

        if @outfit.update(attributes)
          success_response(data: @outfit, serializer: Outfit::ViewSerializer)
        else
          error_response(
            error: { message: I18n.t("outfits.update_failed"), details: @outfit.errors.to_hash },
            status: :unprocessable_entity
          )
        end
      end

      private

      def set_outfit
        @outfit = current_user.outfits
                              .includes(outfit_items: { clothing_item: { image_attachment: :blob } })
                              .find(params[:id])
      end

      def outfit_params
        params.require(:outfit).permit(:status, :rating, :feedback_note)
      end

      def per_page
        [ [ params.fetch(:per_page, 20).to_i, 1 ].max, 50 ].min
      end
    end
  end
end
