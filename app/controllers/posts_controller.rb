class PostsController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  def create
    post = Posts::Create.call(user: current_user, post_params: post_params)
    if post.persisted?
      log_event(event_type: :post_created, subject: post)
      redirect_to root_path
    else
      redirect_to root_path, alert: post.errors.full_messages.to_sentence
    end
  end

  def show
    @post          = Post.includes(comments: :user).find(params[:id])
    @user_reaction = current_user&.reactions&.find_by(reactable: @post)

    render "modal" if turbo_frame_request?
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    log_event(event_type: :post_destroyed, subject: @post) if @post.destroy

    redirect_to user_path(current_user)
  end

  private

  def render_aside?
    false
  end

  def post_params
    params.require(:post).permit(:description, :image)
  end
end
