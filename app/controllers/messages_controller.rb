class MessagesController < ApplicationController
  before_action :authenticate_user!

  rate_limit to: 30, within: 1.minute, only: :create

  def create
    @conversation = current_user.conversations.find_by!(key: params[:conversation_id])
    @message      = Messages::Create.call(conversation: @conversation, user: current_user, body: message_params[:body])

    if @message.persisted?
      log_event(event_type: :message_sent, subject: @message)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      redirect_to conversation_path(@conversation), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
