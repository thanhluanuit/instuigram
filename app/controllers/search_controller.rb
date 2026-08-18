class SearchController < ApplicationController
  def index
    if params[:query].blank?
      @posts = Post.none
    elsif params[:query].start_with?("#")
      query  = params[:query].gsub("#", "")
      @posts = Post.includes(image_attachment: :blob).joins(:hash_tags).where(hash_tags: { name: query })
    else
      @posts = Post.includes(image_attachment: :blob)
                   .where("description like ?", "%#{Post.sanitize_sql_like(params[:query])}%")
    end
  end
end
