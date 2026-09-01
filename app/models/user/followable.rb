# frozen_string_literal: true

module User::Followable
  extend ActiveSupport::Concern

  included do
    has_many :following_relationships, class_name: "Follow",
                                       foreign_key: :follower_id, dependent: :destroy
    has_many :following, through: :following_relationships, source: :followed
    has_many :follower_relationships, class_name: "Follow",
                                      foreign_key: :followed_id, dependent: :destroy
    has_many :followers, through: :follower_relationships, source: :follower

    scope :suggested_for, ->(user) {
      where.not(id: user.id)
        .where.not(id: Follow.select(:followed_id).where(follower_id: user.id))
        .where.not(username: [ nil, "" ])
        .order(followers_count: :desc, id: :asc)
    }
  end

  def following?(user)
    following_relationships.exists?(followed_id: user.id)
  end
end
