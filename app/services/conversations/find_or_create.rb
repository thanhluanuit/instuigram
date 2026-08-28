# frozen_string_literal: true

class Conversations::FindOrCreate < BaseService
  def initialize(user:, other_user:)
    @user       = user
    @other_user = other_user
  end

  def call
    return if user == other_user

    find_conversation || create_conversation
  end

  private

  attr_reader :user, :other_user

  def find_conversation
    Conversation.find_by(participants_key: participants_key)
  end

  def create_conversation
    Conversation.transaction do
      conversation = Conversation.create!(participants_key: participants_key)
      conversation.conversation_participants.create!(user: user)
      conversation.conversation_participants.create!(user: other_user)
      conversation
    end
  rescue ActiveRecord::RecordNotUnique
    find_conversation
  end

  def participants_key
    @participants_key ||= Conversation.key_for(user, other_user)
  end
end
