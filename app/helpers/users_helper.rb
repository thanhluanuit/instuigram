# frozen_string_literal: true

module UsersHelper
  def external_url(url)
    URI.parse(url.to_s).to_s
  rescue URI::InvalidURIError
    nil
  end
end
