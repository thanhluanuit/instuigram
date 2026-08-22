class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def create
    post = current_user.posts.create(post_params)
    if post.persisted?
      PostMailer.published_post(post).deliver_later
      log_event(event_type: :post_created, subject: post)
    end
    redirect_to root_path
  end

  def show
    @post          = Post.includes(comments: :user).find(params[:id])
    @user_reaction = current_user&.reactions&.find_by(reactable: @post)
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    log_event(event_type: :post_destroyed, subject: @post) if @post.destroy

    redirect_to user_path(current_user)
  end

  private

  def post_params
    params.require(:post).permit(:description, :image)
  end
end
