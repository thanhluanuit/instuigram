class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = current_user&.conversations&.find_by(key: params[:id])
    return reject unless conversation

    stream_for conversation
  end
end
