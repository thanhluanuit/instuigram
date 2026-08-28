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
    conversation_participants.find_by(user: user)
  end
end
