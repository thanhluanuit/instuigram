# frozen_string_literal: true

class Follows::Create < BaseService
  def initialize(follower:, followed:)
    @follower = follower
    @followed = followed
  end

  def call
    find_follow || create_follow
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
end
