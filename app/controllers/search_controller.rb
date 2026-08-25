class SearchController < ApplicationController
  def index
    search_response     = Post.search(search_params[:query])
    @posts              = if search_response
                            search_response.page(search_params[:page]).per(10).records(includes: { image_attachment: :blob })
    else
                            Kaminari.paginate_array([]).page(search_params[:page]).per(10)
    end
    @trending_hash_tags = HashTag.trending.to_a
    @suggested_users    = User.suggested_for(current_user).to_a
  end

  private

  def search_params
    params.permit(:query, :page)
  end
end
