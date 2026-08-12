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
        mode, metadata = resolved_visualization_options
        visualization = current_user.outfit_visualizations.new(
          outfit: @outfit,
          mode: mode,
          metadata: metadata
        )
        visualization.reference_image.attach(visualization_params[:reference_image]) if visualization_params[:reference_image].present?
        visualization.metadata["reference_source"] = reference_source(visualization) if visualization.try_on?
        visualization.metadata["source_fingerprint"] = Visualization::SourceFingerprint.call(visualization)

        if (existing = reusable_visualization(visualization))
          purge_transient_reference(visualization)
          return success_response(
            data: existing,
            serializer: OutfitVisualization::ViewSerializer,
            status: existing.ready? ? :ok : :accepted,
            meta: { reused: true }
          )
        end

        if daily_limit_reached?
          purge_transient_reference(visualization)
          return visualization_limit_response
        end

        if visualization.save
          GenerateOutfitVisualizationJob.perform_later(visualization.id)
          success_response(
            data: visualization,
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

      def resolved_visualization_options
        requested_mode = visualization_params[:mode].presence || "flat_lay"
        person_reference_available = visualization_params[:reference_image].present? || current_user.full_body_image.attached?
        return [ requested_mode, {} ] unless requested_mode == "try_on" && !person_reference_available

        [
          "flat_lay",
          {
            "requested_mode" => "try_on",
            "fallback_reason" => "person_reference_missing"
          }
        ]
      end

      def daily_limit_reached?
        limit = Integer(AppConfig.fetch(:visualization_daily_limit, default: DEFAULT_DAILY_LIMIT), exception: false)
                    .to_i.clamp(1, 100)
        local_day = Time.current.in_time_zone(current_user.timezone).all_day
        current_user.outfit_visualizations.where(created_at: local_day).count >= limit
      end

      def reusable_visualization(visualization)
        @outfit.outfit_visualizations
               .joins(:image_attachment)
               .where(mode: visualization.mode, status: :ready)
               .where("outfit_visualizations.metadata ->> 'source_fingerprint' = ?", visualization.metadata["source_fingerprint"])
               .recent_first
               .first || reusable_in_progress_visualization(visualization)
      end

      def reference_source(visualization)
        visualization.reference_image.attached? ? "request" : "profile"
      end

      def reusable_in_progress_visualization(visualization)
        @outfit.outfit_visualizations
               .where(mode: visualization.mode, status: %i[queued processing])
               .where("outfit_visualizations.metadata ->> 'source_fingerprint' = ?", visualization.metadata["source_fingerprint"])
               .recent_first
               .first
      end

      def purge_transient_reference(visualization)
        visualization.reference_image.purge if visualization.reference_image.attached? && !visualization.persisted?
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
