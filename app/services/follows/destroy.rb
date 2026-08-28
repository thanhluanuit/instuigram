# frozen_string_literal: true

class Follows::Destroy < BaseService
  def initialize(follower:, followed:)
    @follower = follower
    @followed = followed
  end

  def call
    follow = Follow.find_by(follower: follower, followed: followed)
    return unless follow&.destroy

    broadcast_counts
    follow
  end

  private

  attr_reader :follower, :followed

  def broadcast_counts
    Follows::BroadcastCounts.call(follower: follower, followed: followed)
  end
end
