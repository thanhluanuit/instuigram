# frozen_string_literal: true

module UsersHelper
  def external_url(url)
    return "" if url.blank?

    parsed = URI.parse(url.to_s)
    parsed.to_s if parsed.is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    nil
  end
end
