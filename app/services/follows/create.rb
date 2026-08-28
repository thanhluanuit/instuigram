# frozen_string_literal: true

class Follows::Create < BaseService
  def initialize(follower:, followed:)
    @follower = follower
    @followed = followed
  end

  def call
    follow = find_follow || create_follow
    broadcast_counts if follow&.previously_new_record?
    follow
  end

  private

  attr_reader :follower, :followed

  def find_follow
    Follow.find_by(follower: follower, followed: followed)
  end

  def create_follow
    Follow.create!(follower: follower, followed: followed)
  rescue ActiveRecord::RecordNotUnique
    find_follow
  end

  def broadcast_counts
    Follows::BroadcastCounts.call(follower: follower, followed: followed)
  end
end
