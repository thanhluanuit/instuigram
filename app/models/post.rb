# == Schema Information
#
# Table name: posts
#
#  id              :bigint           not null, primary key
#  comments_count  :integer          default(0), not null
#  description     :string
#  reactions_count :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
class Post < ApplicationRecord
  include Searchable
  include Imageable

  belongs_to :user
  scope :created_recently, -> { order(created_at: :desc) }
  scope :discoverable_for, ->(user) {
    where.not(user_id: user.id)
      .where.not(user_id: Follow.select(:followed_id).where(follower_id: user.id))
      .order(Arel.sql("posts.reactions_count + posts.comments_count DESC"), created_at: :desc)
  }

  has_many :post_hash_tags, dependent: :destroy
  has_many :hash_tags, through: :post_hash_tags
  has_many :comments, dependent: :destroy
  has_many :reactions, as: :reactable, dependent: :destroy

  DESCRIPTION_LIMIT = 2200

  validates :description, length: { maximum: DESCRIPTION_LIMIT }
  after_commit :create_hash_tags, on: :create

  def create_hash_tags
    extract_name_hash_tags.uniq.each do |name|
      hash_tags << HashTag.find_or_create_by(name: name)
    end
  end

  def extract_name_hash_tags
    description.to_s.scan(/#\w+/).map { |name| name.gsub("#", "") }
  end
end
