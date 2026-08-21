class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def create
    post = current_user.posts.create(post_params)
    PostMailer.published_post(post).deliver_later if post.persisted?
    redirect_to root_path
  end

  def show
    @post          = Post.includes(comments: :user).find(params[:id])
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
