class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])
    comment = current_user.comments.create(comment_params.merge(post: post))
    if comment.persisted?
      log_event(event_type: :comment_created, subject: comment)
      redirect_to post_path(post)
    else
      redirect_to post_path(post), alert: comment.errors.full_messages.to_sentence
    end
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
