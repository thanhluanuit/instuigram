class SearchController < ApplicationController
  def index
    response = Post.search(params[:query])
    @posts = if response
      response.page(params[:page]).per(5).records(includes: { image_attachment: :blob })
    else
      Kaminari.paginate_array([]).page(params[:page])
    end
  end
end
