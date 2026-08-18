class Api::V1::OauthController < Api::BaseController
  skip_before_action :authenticate_request!

  def create
    client = authenticated_client
    if client
      render json: token_response(client), status: :created
    else
      render json: { message: "Invalid credentials" }, status: :unauthorized
    end
  end

  private

  def authenticated_client
    client = Client.find_by(client_id: token_params[:client_id])
    client if client&.authenticate_client_secret(token_params[:client_secret])
  end

  def token_response(client)
    ttl = 1.hour
    {
      token_type: "Bearer",
      expires_in: ttl.to_i,
      access_token: JWT.encode(
        { sub: client.client_id, iat: Time.current.to_i, exp: ttl.from_now.to_i },
        jwt_secret_key, "HS256"
      )
    }
  end

  def token_params
    params.require(:token).permit(:client_id, :client_secret)
  end
end
