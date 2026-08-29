# frozen_string_literal: true

class Follows::Destroy < BaseService
  def initialize(follower:, followed:)
    @follower = follower
    @followed = followed
  end

  def call
    follow = Follow.find_by(follower: follower, followed: followed)
    return unless follow&.destroy

    broadcast_changes
    follow
  end

  private

  attr_reader :follower, :followed

  def broadcast_changes
    Follows::BroadcastCounts.call(follower: follower, followed: followed)
    Follows::BroadcastButton.call(follower: follower, followed: followed, following: false)
  end
end
