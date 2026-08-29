# frozen_string_literal: true

module UsersHelper
  PROFILE_PLACEHOLDER_TABS = {
    "Saved" => "bookmark",
    "Tagged" => "tag"
  }.freeze

  SETTINGS_PLACEHOLDER_TABS = {
    "Authorized Applications" => "v-pills-apps",
    "Email and SMS" => "v-pills-contact",
    "Manage Contacts" => "v-pills-contacts",
    "Privacy and Security" => "v-pills-privacy"
  }.freeze

  def user_monogram(user)
    source = user.username.presence || user.email.to_s
    source.strip.first.to_s.upcase
  end

  def external_url(url)
    return "" if url.blank?

    parsed = URI.parse(url.to_s)
    parsed.to_s if parsed.is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    nil
  end
end
