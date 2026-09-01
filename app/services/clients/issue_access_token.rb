# frozen_string_literal: true

class Clients::IssueAccessToken < BaseService
  TTL = 1.hour

  def initialize(client:)
    @client = client
  end

  def call
    {
      token_type: "Bearer",
      expires_in: TTL.to_i,
      access_token: access_token
    }
  end

  private

  attr_reader :client

  def access_token
    JWT.encode(
      { sub: client.client_id, iat: Time.current.to_i, exp: TTL.from_now.to_i },
      Rails.application.credentials.jwt_secret_key, "HS256"
    )
  end
end
