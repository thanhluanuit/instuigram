class ReactionsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_post

  def create
    reaction = current_user.reactions.find_or_initialize_by(reactable: @post)
    was_new_record = reaction.new_record?
    if reaction.update(reaction_params)
      log_event(event_type: :reaction_created, subject: reaction) if was_new_record
      redirect_to reaction_return_path
    else
      redirect_to reaction_return_path, alert: reaction.errors.full_messages.to_sentence
    end
  end

  def destroy
    current_user.reactions.find_by(reactable: @post)&.destroy

    redirect_to reaction_return_path
  end

  private

  def set_post
    @post = Post.find_by!(key: params[:post_id])
  end

  def reaction_return_path
    return post_path(@post) if reaction_frame_request?

    request.referer.presence || post_path(@post)
  end

  def reaction_frame_request?
    turbo_frame_request_id.in?([ dom_id(@post, :reaction), dom_id(@post, :modal_reaction) ])
  end

  def reaction_params
    reaction_type = params.permit(:reaction_type)[:reaction_type]

    { reaction_type: Reaction.reaction_types.key?(reaction_type) ? reaction_type : "like" }
  end
end
