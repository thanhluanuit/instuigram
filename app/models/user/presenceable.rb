# frozen_string_literal: true

module User::Presenceable
  extend ActiveSupport::Concern

  ONLINE_WINDOW = 1.minute

  def online?
    last_seen_at.present? && last_seen_at > ONLINE_WINDOW.ago
  end
end
