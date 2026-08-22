class SearchController < ApplicationController
  def index
    search_response = Post.search(search_params[:query])
    @posts = if search_response
      search_response.page(search_params[:page]).per(5).records(includes: { image_attachment: :blob })
    else
      Kaminari.paginate_array([]).page(search_params[:page]).per(5)
    end
  end

  private

  def search_params
    params.permit(:query, :page)
  end
end
