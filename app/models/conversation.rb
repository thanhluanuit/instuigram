# == Schema Information
#
# Table name: conversations
#
#  id               :bigint           not null, primary key
#  last_message_at  :datetime
#  participants_key :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  last_message_id  :bigint
#
# Indexes
#
#  index_conversations_on_last_message_id   (last_message_id)
#  index_conversations_on_participants_key  (participants_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (last_message_id => messages.id) ON DELETE => nullify
#
class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :users, through: :conversation_participants
  has_many :messages, dependent: :destroy

  belongs_to :last_message, class_name: "Message", optional: true

  scope :ordered, -> { order(last_message_at: :desc) }

  def self.key_for(user_a, user_b)
    [ user_a.id, user_b.id ].sort.join("-")
  end

  def other_participant(viewer)
    users.find { |user| user != viewer }
  end

  def participant_for(user)
    conversation_participants.detect { |participant| participant.user_id == user.id }
  end

  def mark_read_for(user)
    participant_for(user).update!(unread_count: 0)
  end
end
