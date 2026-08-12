module Api
  module V1
    class MediaController < BaseController
      def show
        blob = ActiveStorage::Blob.find_signed!(params[:id])
        raise ActiveRecord::RecordNotFound unless owned_by_current_user?(blob)

        if Rails.env.production?
          redirect_to blob.url(
            expires_in: 5.minutes,
            disposition: :inline,
            filename: blob.filename,
            content_type: blob.content_type
          ), allow_other_host: true
        else
          send_data blob.download,
                    type: blob.content_type,
                    disposition: :inline,
                    filename: blob.filename.to_s
        end
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        raise ActiveRecord::RecordNotFound
      end

      private

      def owned_by_current_user?(blob)
        blob.attachments.any? do |attachment|
          owned_attachment?(attachment)
        end
      end

      def owned_attachment?(attachment)
        case attachment.record_type
        when "User"
          attachment.record_id == current_user.id
        when "ClothingItem"
          current_user.clothing_items.where(id: attachment.record_id).exists?
        when "OutfitVisualization"
          current_user.outfit_visualizations.where(id: attachment.record_id).exists?
        else
          false
        end
      end
    end
  end
end
