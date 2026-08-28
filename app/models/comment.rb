class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
  belongs_to :user
  has_many :reactions, as: :reactable, dependent: :destroy

  validates :body, presence: true
end
