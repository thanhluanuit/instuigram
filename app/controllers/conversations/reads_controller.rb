class Conversations::ReadsController < ApplicationController
  before_action :authenticate_user!

  def create
    conversation = current_user.conversations.find(params[:conversation_id])
    conversation.participant_for(current_user).update!(unread_count: 0)

    head :no_content
  end
end
