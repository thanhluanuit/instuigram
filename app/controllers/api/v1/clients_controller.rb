class Api::V1::ClientsController < Api::BaseController
  skip_before_action :authenticate_request!

  rate_limit to: 5, within: 3.minutes, only: :create, store: Rails.configuration.x.rate_limit_store,
    with: -> { render json: { message: "Too many attempts. Try again later." }, status: :too_many_requests }

  def create
    user = User.find_by(email: params[:email])
    if user&.valid_password?(params[:password])
      client = user.clients.create
      if client.persisted?
        render json: { client_id: client.client_id, client_secret: client.client_secret }, status: :created
      else
        render json: { message: client.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    else
      render json: { message: "Invalid email or password" }, status: :unauthorized
    end
  end
end
