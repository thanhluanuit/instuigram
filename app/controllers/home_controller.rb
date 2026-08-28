class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @posts          = Post.includes(user: { avatar_attachment: :blob }, image_attachment: :blob)
                          .created_recently
                          .page(params[:page]).per(10).without_count
    @user_reactions = current_user.reactions.where(reactable: @posts).index_by(&:reactable_id)

    respond_to do |format|
      format.html
      format.turbo_stream if params[:page].present?
    end
  end
end
