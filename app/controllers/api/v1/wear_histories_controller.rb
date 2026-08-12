module Api
  module V1
    class WearHistoriesController < BaseController
      def index
        histories = current_user.wear_histories.recent_first.page(params[:page]).per(per_page)
        success_response(
          data: ActiveModelSerializers::SerializableResource.new(histories, each_serializer: WearHistory::ViewSerializer),
          meta: pagination_meta(histories)
        )
      end

      private

      def per_page
        [ [ params.fetch(:per_page, 20).to_i, 1 ].max, 50 ].min
      end
    end
  end
end
