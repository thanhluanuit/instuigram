# == Schema Information
#
# Table name: messages
#
#  id              :bigint           not null, primary key
#  body            :text             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  conversation_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_messages_on_conversation_id_and_created_at  (conversation_id,created_at)
#  index_messages_on_user_id                         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (user_id => users.id)
#
class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  validates :body, presence: true, length: { maximum: 1000 }

  scope :chronological, -> { order(:created_at, :id) }
end
