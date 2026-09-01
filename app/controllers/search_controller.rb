class SearchController < ApplicationController
  before_action :load_trending_hashtags, if: :render_aside?

  def index
    search_response = Post.search(search_params[:query])
    @posts = if search_response
      search_response.page(search_params[:page]).per(10).records(includes: { image_attachment: :blob })
    else
      Post.none.created_recently.page(search_params[:page]).per(10)
    end
  end

  private

  def load_trending_hashtags
    @hashtags = HashTag.trending.limit(6)
  end

  def search_params
    params.permit(:query, :page)
  end
end
