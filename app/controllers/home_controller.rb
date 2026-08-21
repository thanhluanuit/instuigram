class HomeController < ApplicationController
  def index
    if current_user
      @posts          = Post.includes(user: { avatar_attachment: :blob }, image_attachment: :blob)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(5)
      @user_reactions = current_user.reactions.where(reactable: @posts).index_by(&:reactable_id)
    else
      redirect_to new_user_session_path
    end
  end
end
