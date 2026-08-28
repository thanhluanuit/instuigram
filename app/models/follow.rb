class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", counter_cache: :following_count
  belongs_to :followed, class_name: "User", counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :not_self_follow

  private

  def not_self_follow
    errors.add(:followed_id, "can't be yourself") if follower_id == followed_id
  end
end
