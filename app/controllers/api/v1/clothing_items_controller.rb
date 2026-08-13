module Api
  module V1
    class ClothingItemsController < BaseController
      before_action :set_clothing_item, only: %i[show update destroy reanalyze polish]
      before_action :require_ai_processing_consent!, if: :ai_processing_requested?

      def index
        items = filtered_clothing_items.recent_first.page(params[:page]).per(per_page)
        success_response(data: items, serializer: ClothingItem::ViewSerializer)
      end

      def show
        success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer)
      end

      def create
        item = current_user.clothing_items.new(assignable_clothing_item_params.except(:image))
        item.wardrobe = current_user.wardrobe || current_user.create_wardrobe!(name: Wardrobe::DEFAULT_NAME)
        item.status = :processing if clothing_item_params[:image].present?
        item.image.attach(clothing_item_params[:image]) if clothing_item_params[:image].present?
        set_waiting_polish_metadata(item) if item.image.attached? && ClothingImage.auto_polish_enabled?

        if item.save
          schedule_analysis(item) if item.image.attached?
          success_response(data: item, serializer: ClothingItem::ViewSerializer, status: :created)
        else
          clothing_item_error_response(item, fallback_key: "clothing_items.create_failed")
        end
      rescue ActiveRecord::RecordNotUnique
        duplicate_image_response
      end

      def update
        image = clothing_item_params[:image]
        @clothing_item.assign_attributes(assignable_clothing_item_params.except(:image))
        @clothing_item.image.attach(image) if image.present?
        @clothing_item.status = :processing if image.present?
        @clothing_item.ai_analyzed_at = nil if image.present?
        @clothing_item.ai_metadata = @clothing_item.ai_metadata.except("error") if image.present?

        if @clothing_item.save
          reset_polished_image(@clothing_item) if image.present?
          schedule_analysis(@clothing_item) if image.present?
          success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer)
        else
          clothing_item_error_response(@clothing_item, fallback_key: "clothing_items.update_failed")
        end
      rescue ActiveRecord::RecordNotUnique
        duplicate_image_response
      end

      def destroy
        @clothing_item.discard!
        success_response(data: { message: I18n.t("clothing_items.deleted") })
      end

      def reanalyze
        unless @clothing_item.image.attached?
          return error_response(error: { message: I18n.t("clothing_items.image_required") }, status: :unprocessable_entity)
        end

        @clothing_item.mark_processing!
        schedule_analysis(@clothing_item)
        success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer)
      end

      def polish
        unless @clothing_item.image.attached?
          return error_response(error: { message: I18n.t("clothing_items.image_required") }, status: :unprocessable_entity)
        end

        if polish_in_progress_for_current_source?(@clothing_item)
          return success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer, status: :accepted)
        end

        @clothing_item.polished_image.purge if @clothing_item.polished_image.attached?
        update_polish_metadata(@clothing_item, "queued", "source_checksum" => @clothing_item.image_checksum)
        GenerateClothingItemPolishedImageJob.perform_later(@clothing_item.id, @clothing_item.image_checksum)
        success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer, status: :accepted)
      end

      private

      def filtered_clothing_items
        items = current_user.clothing_items.active
        items = items.where(status: params[:status]) if params[:status].present?
        items = items.where(category: params[:category]) if params[:category].present?
        items = items.where(primary_color: params[:primary_color]) if params[:primary_color].present?
        items
      end

      def set_clothing_item
        @clothing_item = current_user.clothing_items.active.find(params[:id])
      end

      def clothing_item_params
        params.require(:clothing_item).permit(
          :name,
          :garment_type,
          :category,
          :subcategory,
          :primary_color,
          :pattern,
          :material,
          :fit,
          :formality_score,
          :image,
          :use_ai_usage_tags,
          secondary_colors: [],
          season_tags: [],
          occasion_tags: [],
          style_tags: [],
          cultural_tags: [],
          user_usage_tags: []
        )
      end

      def assignable_clothing_item_params
        clothing_item_params.except(:use_ai_usage_tags).tap do |attributes|
          attributes[:user_usage_tags] = nil if ActiveModel::Type::Boolean.new.cast(clothing_item_params[:use_ai_usage_tags])
        end
      end

      def per_page
        [ [ params.fetch(:per_page, 25).to_i, 1 ].max, 100 ].min
      end

      def schedule_analysis(clothing_item)
        AnalyzeClothingItemJob.perform_later(clothing_item.id)
      end

      def reset_polished_image(clothing_item)
        clothing_item.polished_image.purge if clothing_item.polished_image.attached?
        if ClothingImage.auto_polish_enabled?
          update_polish_metadata(clothing_item, "waiting_for_analysis", "source_checksum" => clothing_item.image_checksum)
        else
          update_polish_metadata(clothing_item, "not_requested")
        end
      end

      def set_waiting_polish_metadata(clothing_item)
        clothing_item.ai_metadata = clothing_item.ai_metadata.merge(
          "image_polish" => { "status" => "waiting_for_analysis", "source_checksum" => clothing_item.image.blob.checksum }
        )
      end

      def update_polish_metadata(clothing_item, status, extra = {})
        clothing_item.update_column(
          :ai_metadata,
          clothing_item.ai_metadata.merge("image_polish" => { "status" => status }.merge(extra))
        )
      end

      def polish_in_progress_for_current_source?(clothing_item)
        metadata = clothing_item.ai_metadata.fetch("image_polish", {})
        metadata["status"].in?(%w[queued processing]) && metadata["source_checksum"] == clothing_item.image_checksum
      end

      def clothing_item_error_response(clothing_item, fallback_key:)
        message_key = clothing_item.errors.added?(:image, :taken) ? "clothing_items.duplicate_image" : fallback_key
        error_response(
          error: { message: I18n.t(message_key), details: clothing_item.errors.to_hash },
          status: :unprocessable_entity
        )
      end

      def duplicate_image_response
        error_response(error: { message: I18n.t("clothing_items.duplicate_image") }, status: :unprocessable_entity)
      end

      def ai_processing_requested?
        return true if action_name.in?(%w[reanalyze polish])
        return false unless action_name.in?(%w[create update])

        clothing_item_params[:image].present?
      end
    end
  end
end
