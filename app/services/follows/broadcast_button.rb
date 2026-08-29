# frozen_string_literal: true

class Follows::BroadcastButton < BaseService
  def initialize(follower:, followed:, following:)
    @follower  = follower
    @followed  = followed
    @following = following
  end

  def call
    Turbo::StreamsChannel.broadcast_action_to(
      [ follower, :follow_state ],
      action:  :replace,
      targets: "[data-follow-user-id='#{followed.id}']",
      partial: "users/follow_button",
      locals:  { user: followed, following: following }
    )
  end

  private

  attr_reader :follower, :followed, :following
end
