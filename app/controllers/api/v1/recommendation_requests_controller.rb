module Api
  module V1
    class RecommendationRequestsController < BaseController
      def index
        requests = current_user.recommendation_requests
                               .recent_first
                               .includes(outfits: { outfit_items: { clothing_item: { image_attachment: :blob } } })
                               .page(params[:page])
                               .per(per_page)

        success_response(
          data: ActiveModelSerializers::SerializableResource.new(
            requests,
            each_serializer: RecommendationRequest::ViewSerializer
          ),
          meta: pagination_meta(requests)
        )
      end

      def show
        request = current_user.recommendation_requests
                              .includes(outfits: { outfit_items: { clothing_item: { image_attachment: :blob } } })
                              .find(params[:id])
        success_response(data: request, serializer: RecommendationRequest::ViewSerializer)
      end

      private

      def per_page
        [ [ params.fetch(:per_page, 20).to_i, 1 ].max, 50 ].min
      end
    end
  end
end
