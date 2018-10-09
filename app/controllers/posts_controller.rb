class PostsController < ApplicationController
  def create
    Post.create(post_params)
    redirect_to root_path
  end

  private

  def post_params
    params.require(:post).permit(:description, :image, :user_id)
  end
end
