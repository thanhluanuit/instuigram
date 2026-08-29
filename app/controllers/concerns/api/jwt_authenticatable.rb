module Api::JwtAuthenticatable
  extend ActiveSupport::Concern

  MissingSecretKey = Class.new(StandardError)

  def self.secret_key(credential = Rails.application.credentials.jwt_secret_key, env: Rails.env)
    return credential if credential.present?
    raise MissingSecretKey, "credentials.jwt_secret_key is required in #{env}" unless env.local?

    Rails.application.key_generator.generate_key("Api::JwtAuthenticatable access token", 32)
  end

  included do
    include ActionController::HttpAuthentication::Token::ControllerMethods
    before_action :authenticate_request!
  end

  private

  def authenticate_request!
    render_unauthorized unless current_user_api
  end

  def current_user_api
    @current_user_api ||= current_client&.user
  end

  def current_client
    @current_client ||= authenticate_with_http_token do |token, _options|
      payload, = JWT.decode(token, jwt_secret_key, true, algorithm: "HS256")
      Client.find_by(client_id: payload["sub"])
    rescue JWT::DecodeError
      nil
    end
  end

  def jwt_secret_key
    Api::JwtAuthenticatable.secret_key
  end

  def render_unauthorized
    render json: { message: "Unauthorized" }, status: :unauthorized
  end
end
