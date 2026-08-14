module Api
  module V1
    class OutfitVisualizationsController < BaseController
      DEFAULT_DAILY_LIMIT = 10

      before_action :set_outfit
      before_action :set_visualization, only: :show
      before_action :require_ai_processing_consent!, only: :create

      def index
        visualizations = @outfit.outfit_visualizations.recent_first.page(params[:page]).per(per_page)
        success_response(
          data: ActiveModelSerializers::SerializableResource.new(
            visualizations,
            each_serializer: OutfitVisualization::ViewSerializer
          ),
          meta: pagination_meta(visualizations)
        )
      end

      def show
        success_response(data: @visualization, serializer: OutfitVisualization::ViewSerializer)
      end

      def create
        result = Visualization::Request.call(
          user: current_user,
          outfit: @outfit,
          mode: visualization_params[:mode].presence || "flat_lay",
          reference_image: visualization_params[:reference_image]
        )

        if result.reused
          return success_response(
            data: result.visualization,
            serializer: OutfitVisualization::ViewSerializer,
            status: result.visualization.ready? ? :ok : :accepted,
            meta: { reused: true }
          )
        end

        return visualization_limit_response if result.limited

        if result.visualization.present?
          success_response(
            data: result.visualization,
            serializer: OutfitVisualization::ViewSerializer,
            status: :accepted,
            meta: { reused: false }
          )
        else
          error_response(
            error: { message: I18n.t("visualizations.create_failed"), details: visualization.errors.to_hash },
            status: :unprocessable_entity
          )
        end
      end

      private

      def set_outfit
        @outfit = current_user.outfits.includes(clothing_items: { image_attachment: :blob }).find(params[:outfit_id])
      end

      def set_visualization
        @visualization = @outfit.outfit_visualizations.find(params[:id])
      end

      def visualization_params
        params.require(:visualization).permit(:mode, :reference_image)
      end

      def visualization_limit_response
        error_response(error: { message: I18n.t("visualizations.daily_limit_reached") }, status: :too_many_requests)
      end

      def per_page
        [ [ params.fetch(:per_page, 20).to_i, 1 ].max, 50 ].min
      end
    end
  end
end
