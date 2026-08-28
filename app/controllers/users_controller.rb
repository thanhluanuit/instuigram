class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update ]

  def show
    @user  = User.find(params[:id])
    @posts = @user.posts.includes(image_attachment: :blob)
                  .created_recently
                  .page(params[:page]).per(10)
  end

  def edit
  end

  def update
    log_event(event_type: :profile_updated, subject: current_user) if current_user.update(user_params)
    redirect_to current_user
  end

  private

  def user_params
    params.require(:user).permit(:username, :name, :website,
                                 :bio, :email, :phone, :gender, :avatar)
  end
end
