class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])
    current_user.comments.create(comment_params.merge(post: post))

    redirect_to post_path(post)
  end

  def destroy
    comment = current_user.comments.find(params[:id])
    post_id = comment.post_id
    comment.destroy

    redirect_to post_path(post_id)
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
