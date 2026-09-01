# frozen_string_literal: true

module User::Conversable
  extend ActiveSupport::Concern

  included do
    has_many :conversation_participants
    has_many :conversations, through: :conversation_participants
    has_many :messages, dependent: :destroy

    before_destroy :destroy_conversations
  end

  def unread_messages_count
    conversation_participants.sum(:unread_count)
  end

  private

  def destroy_conversations
    Conversation.where(id: conversations.ids).destroy_all
  end
end
