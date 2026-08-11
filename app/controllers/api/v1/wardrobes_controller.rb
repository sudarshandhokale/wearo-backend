module Api
  module V1
    class WardrobesController < BaseController
      def show
        success_response(data: wardrobe, serializer: Wardrobe::ViewSerializer)
      end

      private

      def wardrobe
        @wardrobe ||= current_user.wardrobe || current_user.create_wardrobe!(name: Wardrobe::DEFAULT_NAME)
      end
    end
  end
end
