# frozen_string_literal: true

module User::Presenceable
  extend ActiveSupport::Concern

  ONLINE_WINDOW = 1.minute
  HEARTBEAT_INTERVAL = ONLINE_WINDOW / 2

  def online?
    last_seen_at.present? && last_seen_at > ONLINE_WINDOW.ago
  end

  def touch_last_seen
    update_column(:last_seen_at, Time.current)
  end
end
