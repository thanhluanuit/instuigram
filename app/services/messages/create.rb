# frozen_string_literal: true

class Messages::Create < BaseService
  def initialize(conversation:, user:, body:)
    @conversation = conversation
    @user         = user
    @body         = body
  end

  def call
    message = conversation.messages.new(user: user, body: body)

    Message.transaction do
      if message.save
        conversation.update_columns(last_message_id: message.id, last_message_at: message.created_at)
        update_unread_counts
      end
    end

    broadcast(message) if message.persisted?

    message
  end

  private

  attr_reader :conversation, :user, :body

  def update_unread_counts
    conversation.conversation_participants.where.not(user_id: user.id)
                .update_all("unread_count = unread_count + 1")
    conversation.conversation_participants.where(user_id: user.id).update_all(unread_count: 0)
  end

  def broadcast(message)
    ConversationChannel.broadcast_to(conversation, render_message(message))
    broadcast_inbox(message)
  end

  def render_message(message)
    ApplicationController.render(
      partial: "messages/broadcast",
      formats: [ :turbo_stream ],
      locals:  { message: message }
    )
  end

  def broadcast_inbox(message)
    participants = conversation.conversation_participants.includes(:user).to_a
    totals = ConversationParticipant.unread_totals_for(participants.map(&:user_id))

    participants.each do |participant|
      InboxChannel.broadcast_to(participant.user,
                                conversation_id: conversation.id,
                                unread_count:    participant.unread_count,
                                total_unread:    totals[participant.user_id],
                                preview:         message.body,
                                sender:          user.username)
    end
  end
end
