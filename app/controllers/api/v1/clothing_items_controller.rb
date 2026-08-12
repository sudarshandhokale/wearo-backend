module Api
  module V1
    class ClothingItemsController < BaseController
      before_action :set_clothing_item, only: %i[show update destroy reanalyze]

      def index
        items = filtered_clothing_items.recent_first.page(params[:page]).per(per_page)
        success_response(data: items, serializer: ClothingItem::ViewSerializer)
      end

      def show
        success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer)
      end

      def create
        item = current_user.clothing_items.new(clothing_item_params.except(:image))
        item.wardrobe = current_user.wardrobe || current_user.create_wardrobe!(name: Wardrobe::DEFAULT_NAME)
        item.status = :processing if clothing_item_params[:image].present?
        item.image.attach(clothing_item_params[:image]) if clothing_item_params[:image].present?

        if item.save
          success_response(data: item, serializer: ClothingItem::ViewSerializer, status: :created)
        else
          error_response(error: { message: I18n.t("clothing_items.create_failed"), details: item.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      def update
        if @clothing_item.update(clothing_item_params.except(:image))
          @clothing_item.image.attach(clothing_item_params[:image]) if clothing_item_params[:image].present?
          success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer)
        else
          error_response(error: { message: I18n.t("clothing_items.update_failed"), details: @clothing_item.errors.to_hash }, status: :unprocessable_entity)
        end
      end

      def destroy
        @clothing_item.discard!
        success_response(data: { message: I18n.t("clothing_items.deleted") })
      end

      def reanalyze
        @clothing_item.update!(status: :processing)
        success_response(data: @clothing_item, serializer: ClothingItem::ViewSerializer)
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
          :category,
          :subcategory,
          :primary_color,
          :pattern,
          :material,
          :formality_score,
          :image,
          secondary_colors: [],
          season_tags: [],
          occasion_tags: [],
          style_tags: []
        )
      end

      def per_page
        [ [ params.fetch(:per_page, 25).to_i, 1 ].max, 100 ].min
      end
    end
  end
end
