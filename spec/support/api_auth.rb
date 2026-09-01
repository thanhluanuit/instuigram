# frozen_string_literal: true

module ApiAuth
  def issue_access_token(client)
    Clients::IssueAccessToken.call(client: client)[:access_token]
  end
end
