class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user  = current_user
    @posts = @user.posts.includes(image_attachment: :blob)
                  .created_recently
                  .page(params[:page]).per(10)

    render "users/show"
  end

  def edit
  end

  def update
    if current_user.update(user_params)
      log_event(event_type: :profile_updated, subject: current_user)
      redirect_to profile_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def render_aside?
    super && action_name == "show"
  end

  def user_params
    params.require(:user).permit(:username, :name, :website,
                                 :bio, :email, :phone, :gender, :avatar)
  end
end
