class ApplicationController < ActionController::API
  include ResponseHandler

  rescue_from ActiveRecord::RecordNotFound do |exception|
    error_response(error: { message: exception.message }, status: :not_found)
  end

  rescue_from ActionController::ParameterMissing do |exception|
    error_response(error: { message: exception.message }, status: :bad_request)
  end
end
