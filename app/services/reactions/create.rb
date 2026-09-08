# frozen_string_literal: true

class Reactions::Create < BaseService
  def initialize(user:, post:, reaction_type:)
    @user          = user
    @post          = post
    @reaction_type = reaction_type
  end

  def call
    reaction = user.reactions.find_or_initialize_by(reactable: post)
    reaction.update(reaction_type: reaction_type)
    Reactions::Broadcast.call(post: post, user: user, liked: true) if reaction.previously_new_record?
    reaction
  end

  private

  attr_reader :user, :post, :reaction_type
end
