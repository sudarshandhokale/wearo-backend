module Api
  module V1
    class MetadataController < BaseController
      def index
        success_response(data: Metadata::Catalog.all)
      end
    end
  end
end
