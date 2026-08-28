class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_user.conversations
                                 .includes(:conversation_participants,
                                           { last_message: :user },
                                           users: { avatar_attachment: :blob })
                                 .ordered
                                 .page(params[:page]).per(10)
  end

  def show
    @conversation = current_user.conversations
                                .includes(users: { avatar_attachment: :blob })
                                .find(params[:id])
    @messages     = @conversation.messages.includes(:user).chronological.last(50)

    @conversation.mark_read_for(current_user)
  end

  def new
    @users = User.excluding(current_user)
                 .matching_username(params[:query])
                 .includes(avatar_attachment: :blob)
                 .order(:username)
                 .page(params[:page]).per(10)
  end

  def create
    other_user = User.find(params[:user_id])
    return redirect_to conversations_path, alert: "You cannot message yourself." if other_user == current_user

    conversation = Conversations::FindOrCreate.call(user: current_user, other_user: other_user)
    return redirect_to conversations_path, alert: "Could not start that conversation." unless conversation

    redirect_to conversation_path(conversation)
  end
end
