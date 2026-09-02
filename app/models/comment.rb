# == Schema Information
#
# Table name: comments
#
#  id              :bigint           not null, primary key
#  body            :text             not null
#  reactions_count :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  post_id         :bigint           not null
#  user_id         :bigint           not null
#
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
  belongs_to :user
  has_many :reactions, as: :reactable, dependent: :destroy

  validates :body, presence: true
end
