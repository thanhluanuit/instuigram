# == Schema Information
#
# Table name: posts
#
#  id              :bigint           not null, primary key
#  comments_count  :integer          default(0), not null
#  description     :string
#  key             :string           not null
#  reactions_count :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
class Post < ApplicationRecord
  include Keyable
  include Searchable
  include Imageable
  include HashTaggable

  DESCRIPTION_LIMIT = 2200

  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy

  validates :description, length: { maximum: DESCRIPTION_LIMIT }

  scope :created_recently, -> { order(created_at: :desc) }
  scope :discoverable_for, ->(user) {
    where.not(user_id: user.id)
      .where.not(user_id: Follow.select(:followed_id).where(follower_id: user.id))
      .order(Arel.sql("posts.reactions_count + posts.comments_count DESC"), created_at: :desc)
  }
end
