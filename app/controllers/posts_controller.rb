class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def create
    current_user.posts.create(post_params)
    redirect_to root_path
  end

  def show
    @post          = Post.find(params[:id])
    @user_reaction = current_user&.reactions&.find_by(reactable: @post)
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy

    redirect_to user_path(current_user)
  end

  private

  def post_params
    params.require(:post).permit(:description, :image)
  end
end
