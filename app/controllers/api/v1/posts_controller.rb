class Api::V1::PostsController < Api::BaseController
  def index
    posts = current_user_api.posts.includes(:hash_tags, image_attachment: :blob)
                                   .created_recently.page(params[:page]).per(10)
    render json: {
      posts: posts.map { |post| post_json(post) },
      current_page: posts.current_page,
      total_pages: posts.total_pages
    }
  end

  def show
    post = current_user_api.posts.find_by!(key: params[:id])
    render json: post_json(post)
  end

  def create
    post = Posts::Create.call(user: current_user_api, post_params: post_params)
    if post.persisted?
      render json: post_json(post), status: :created
    else
      render json: { message: post.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    post = current_user_api.posts.find_by!(key: params[:id])
    post.destroy
    head :no_content
  end

  private

  def post_params
    params.require(:post).permit(:description, :image)
  end

  def post_json(post)
    {
      id: post.id,
      description: post.description,
      image_url: post.image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(post.image) : nil,
      hash_tags: post.hashtag_names,
      created_at: post.created_at
    }
  end
end
