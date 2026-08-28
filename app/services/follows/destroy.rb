# frozen_string_literal: true

class Follows::Destroy < BaseService
  def initialize(follower:, followed:)
    @follower = follower
    @followed = followed
  end

  def call
    follow = Follow.find_by(follower: follower, followed: followed)
    follow&.destroy
    follow
  end

  private

  attr_reader :follower, :followed
end
