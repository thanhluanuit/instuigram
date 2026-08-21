class Reaction < ApplicationRecord
  REACTION_TYPES = { like: "like", love: "love", haha: "haha", wow: "wow", sad: "sad", angry: "angry" }.freeze

  belongs_to :user
  belongs_to :reactable, polymorphic: true, counter_cache: :reactions_count

  enum :reaction_type, REACTION_TYPES, default: :like

  validates :user_id, uniqueness: { scope: [ :reactable_type, :reactable_id ] }

  after_commit :broadcast_reactions_count

  private

  def broadcast_reactions_count
    return unless reactable_type == "Post"

    PostChannel.broadcast_to(reactable, reactions_count: reactable.reload.reactions_count)
  rescue ActiveRecord::RecordNotFound
  end
end
