class PresenceChannel < ApplicationCable::Channel
  periodically :touch_presence, every: 30.seconds

  def subscribed
    return reject unless current_user

    stream_from "presence"
    touch_presence
  end

  def unsubscribed
    return unless current_user

    current_user.update_column(:last_seen_at, Time.current)
  end

  private

  def touch_presence
    came_online = !current_user.online?
    current_user.update_column(:last_seen_at, Time.current)

    return unless came_online

    ActionCable.server.broadcast("presence", { user_id: current_user.id, online: true })
  end
end
