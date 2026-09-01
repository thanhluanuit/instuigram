class Api::V1::OauthController < Api::BaseController
  skip_before_action :authenticate_request!

  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { render json: { message: "Too many attempts. Try again later." }, status: :too_many_requests }

  def create
    client = authenticated_client
    if client
      render json: Clients::IssueAccessToken.call(client: client), status: :created
    else
      render json: { message: "Invalid credentials" }, status: :unauthorized
    end
  end

  private

  def authenticated_client
    client = Client.find_by(client_id: token_params[:client_id])
    client if client&.authenticate_client_secret(token_params[:client_secret])
  end

  def token_params
    params.require(:token).permit(:client_id, :client_secret)
  end
end
