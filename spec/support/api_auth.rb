# frozen_string_literal: true

module ApiAuth
  def issue_access_token(client)
    JWT.encode(
      { sub: client.client_id, iat: Time.current.to_i, exp: 1.hour.from_now.to_i },
      Rails.application.credentials.jwt_secret_key, "HS256"
    )
  end
end
