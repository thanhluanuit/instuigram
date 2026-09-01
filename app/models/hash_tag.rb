# == Schema Information
#
# Table name: hash_tags
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hash_tags_on_name  (name) UNIQUE
#
class HashTag < ApplicationRecord
  has_many :post_hash_tags, dependent: :destroy
  has_many :posts, through: :post_hash_tags

  scope :trending, -> {
    joins(:post_hash_tags)
      .group(:id)
      .order(Arel.sql("COUNT(post_hash_tags.id) DESC"), name: :asc)
  }
end
