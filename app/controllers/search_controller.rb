class SearchController < ApplicationController
  before_action :redirect_signed_in_to_explore

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

  def render_aside?
    false
  end

  def redirect_signed_in_to_explore
    redirect_to explore_path if user_signed_in? && search_params[:query].blank?
  end

  def matching_users
    query = search_params[:query].to_s
    return User.none if query.blank? || query.start_with?("#")

    User.matching_username(query)
        .includes(avatar_attachment: :blob)
        .order(followers_count: :desc, id: :asc)
        .limit(5)
        .load
  end

  def following_ids_for(users)
    return Set.new if !user_signed_in? || users.empty?

    current_user.following_relationships
                .where(followed_id: users.map(&:id))
                .pluck(:followed_id).to_set
  end

  def search_params
    params.permit(:query, :page)
  end
end
