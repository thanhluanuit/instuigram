# frozen_string_literal: true

class Follows::BroadcastCounts < BaseService
  include ActionView::RecordIdentifier

  def initialize(follower:, followed:)
    @follower = follower
    @followed = followed
  end

  def call
    broadcast_count(followed, :followers_count)
    broadcast_count(follower, :following_count)
  end

  private

  attr_reader :follower, :followed

  def broadcast_count(user, counter)
    Turbo::StreamsChannel.broadcast_replace_later_to(
      [ user, :follows ],
      target:  dom_id(user, counter),
      partial: "users/#{counter}",
      locals:  { user: user }
    )
  end
end
