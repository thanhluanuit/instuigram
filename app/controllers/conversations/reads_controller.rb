class Conversations::ReadsController < ApplicationController
  before_action :authenticate_user!

  def create
    conversation = current_user.conversations.find(params[:conversation_id])
    conversation.mark_read_for(current_user)

    head :no_content
  end
end
