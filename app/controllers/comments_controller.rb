class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    @post    = Post.find(params[:post_id])
    @comment = current_user.comments.create(comment_params.merge(post: @post))

    return render_rejected_comment unless @comment.persisted?

    log_event(event_type: :comment_created, subject: @comment)
    render_post_comments
  end

  def destroy
    comment = current_user.comments.find(params[:id])
    @post   = comment.post
    comment.destroy

    render_post_comments
  end

  private

  def render_rejected_comment
    alert = @comment.errors.full_messages.to_sentence

    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = alert
        @post = Post.includes(comments: :user).find(@post.id)
        render :create, status: :unprocessable_entity
      end
      format.html { redirect_to post_path(@post), alert: alert }
    end
  end

  def render_post_comments
    respond_to do |format|
      format.turbo_stream do
        @post = Post.includes(comments: :user).find(@post.id)
        render :create
      end
      format.html { redirect_to post_path(@post) }
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
