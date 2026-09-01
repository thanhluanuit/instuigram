class SearchController < ApplicationController
  before_action :redirect_signed_in_to_explore
  before_action :load_trending_hashtags, if: :render_aside?

  def index
    search_response = Post.search(search_params[:query])
    @posts = if search_response
      search_response.page(search_params[:page]).per(10).records(includes: { image_attachment: :blob })
    else
      Post.none.created_recently.page(search_params[:page]).per(10)
    end
    @users         = matching_users
    @following_ids = following_ids_for(@users)
  end

  private

  def redirect_signed_in_to_explore
    redirect_to explore_path if user_signed_in? && search_params[:query].blank?
  end

  def matching_users
    User.matching_username(search_params[:query])
        .includes(avatar_attachment: :blob)
        .order(followers_count: :desc, id: :asc)
        .limit(5)
        .load
  end

  def following_ids_for(users)
    return Set.new unless user_signed_in?

    current_user.following_relationships
                .where(followed_id: users.map(&:id))
                .pluck(:followed_id).to_set
  end

  def load_trending_hashtags
    @hashtags = HashTag.trending.limit(6)
  end

  def search_params
    params.permit(:query, :page)
  end
end
