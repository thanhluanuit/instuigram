class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user  = current_user
    @posts = @user.posts.includes(image_attachment: :blob)
                  .created_recently
                  .page(params[:page]).per(10)

    render "users/show"
  end
end
