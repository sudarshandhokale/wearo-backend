class ApplicationController < ActionController::API
  include ResponseHandler

  attr_reader :current_user

  rescue_from StandardError, with: :handle_internal_error

  rescue_from ActiveRecord::RecordNotFound do
    error_response(error: { message: I18n.t("errors.messages.not_found") }, status: :not_found)
  end

  rescue_from ActionController::ParameterMissing do
    error_response(error: { message: I18n.t("errors.messages.bad_request") }, status: :bad_request)
  end

  private

  def handle_internal_error(error)
    Rails.logger.error("Unhandled API error: #{error.class}: #{error.message}")
    error_response(error: { message: I18n.t("errors.messages.internal_server_error") }, status: :internal_server_error)
  end

  def authenticate_user!
    return error_response(error: { message: I18n.t("errors.messages.unauthorized") }, status: :unauthorized) if bearer_token.blank?

    payload = Auth::Token.decode(bearer_token)
    @current_user = User.find(payload[:sub])
  rescue Auth::Token::DecodeError, Auth::Token::RevokedTokenError, ActiveRecord::RecordNotFound
    error_response(error: { message: I18n.t("errors.messages.unauthorized") }, status: :unauthorized)
  end

  def bearer_token
    request.headers["Authorization"].to_s.split(" ").last
  end
end
