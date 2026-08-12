module Api
  module V1
    class ExternalContextsController < BaseController
      def show
        result = ExternalContext::Fetch.call(
          user: current_user,
          city: params[:city],
          start_date: params[:start_date],
          end_date: params[:end_date]
        )
        success_response(data: {
          city: result.city,
          country_code: result.country_code,
          weather: result.weather
        })
      rescue ExternalContext::InvalidDateRangeError
        error_response(error: { message: I18n.t("external_context.invalid_date_range") }, status: :unprocessable_entity)
      end
    end
  end
end
