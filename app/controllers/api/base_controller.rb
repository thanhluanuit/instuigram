class Api::BaseController < ActionController::API
  include Api::JwtAuthenticatable

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found
    render json: { message: "Not found" }, status: :not_found
  end
end
