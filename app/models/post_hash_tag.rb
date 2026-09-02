# == Schema Information
#
# Table name: post_hash_tags
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  hash_tag_id :bigint           not null
#  post_id     :bigint           not null
#
class PostHashTag < ApplicationRecord
  belongs_to :post
  belongs_to :hash_tag
end
