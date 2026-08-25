class HashTag < ApplicationRecord
  has_many :post_hash_tags, dependent: :destroy
  has_many :posts, through: :post_hash_tags

  scope :trending, ->(limit: 5) {
    joins(:post_hash_tags).group(:id).order(Arel.sql("COUNT(post_hash_tags.id) DESC")).limit(limit)
  }
end
