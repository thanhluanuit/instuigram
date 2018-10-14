class HomeController < ApplicationController
  def index
    if current_user
      @posts = Post.order(created_at: :desc).page(params[:page]).per(5)
    else
      redirect_to new_user_session_path
    end
  end
end
