class Reaction < ApplicationRecord
  REACTION_TYPES = { like: "like", love: "love", haha: "haha", wow: "wow", sad: "sad", angry: "angry" }.freeze

  belongs_to :user
  belongs_to :reactable, polymorphic: true, counter_cache: :reactions_count

  enum :reaction_type, REACTION_TYPES, default: :like

  validates :user_id, uniqueness: { scope: [ :reactable_type, :reactable_id ] }

  after_commit :broadcast_reaction_changes

  private

  def broadcast_reaction_changes
    return unless reactable_type == "Post"

    PostChannel.broadcast_to(reactable, reactions_count: reactable.reload.reactions_count)
    PostChannel.broadcast_to([ reactable, user ], liked: !destroyed?)
  rescue ActiveRecord::RecordNotFound
  end
end
