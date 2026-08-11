class ApplicationController < ActionController::API
  include ResponseHandler

  attr_reader :current_user

  rescue_from ActiveRecord::RecordNotFound do |exception|
    error_response(error: { message: exception.message }, status: :not_found)
  end

  rescue_from ActionController::ParameterMissing do |exception|
    error_response(error: { message: exception.message }, status: :bad_request)
  end

  private

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
