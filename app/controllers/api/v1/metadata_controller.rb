module Api
  module V1
    class MetadataController < BaseController
      skip_before_action :authenticate_user!

      def index
        success_response(data: Metadata::Catalog.all)
      end
    end
  end
end
