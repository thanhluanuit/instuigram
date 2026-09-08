# frozen_string_literal: true

class Reactions::Destroy < BaseService
  def initialize(user:, post:)
    @user = user
    @post = post
  end

  def call
    reaction = user.reactions.find_by(reactable: post)
    return unless reaction&.destroy

    Reactions::Broadcast.call(post: post, user: user, liked: false)
    reaction
  end

  private

  attr_reader :user, :post
end
