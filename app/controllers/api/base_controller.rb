class Api::BaseController < ActionController::API
  include Api::JwtAuthenticatable

  self.cache_store = Rails.configuration.x.rate_limit_store

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def render_not_found
    render json: { message: "Not found" }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { message: exception.message }, status: :bad_request
  end
end
