# frozen_string_literal: true

class Reactions::Broadcast < BaseService
  def initialize(post:, user:, liked:)
    @post  = post
    @user  = user
    @liked = liked
  end

  def call
    PostChannel.broadcast_to(post, reactions_count: post.reload.reactions_count)
    PostChannel.broadcast_to([ post, user ], liked: liked)
  end

  private

  attr_reader :post, :user, :liked
end
