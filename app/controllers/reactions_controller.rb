class ReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    reaction = current_user.reactions.find_or_initialize_by(reactable: @post)
    reaction.update(reaction_params)

    redirect_back(fallback_location: post_path(@post))
  end

  def destroy
    current_user.reactions.find_by(reactable: @post)&.destroy

    redirect_back(fallback_location: post_path(@post))
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def reaction_params
    reaction_type = params.permit(:reaction_type)[:reaction_type]

    { reaction_type: Reaction.reaction_types.key?(reaction_type) ? reaction_type : "like" }
  end
end
