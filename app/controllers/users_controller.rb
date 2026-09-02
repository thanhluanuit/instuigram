class UsersController < ApplicationController
  def show
    @user = User.find_by!(key: params[:id])
    return redirect_to profile_path if @user == current_user

    @posts = @user.posts.includes(image_attachment: :blob)
                  .created_recently
                  .page(params[:page]).per(10)
  end
end
