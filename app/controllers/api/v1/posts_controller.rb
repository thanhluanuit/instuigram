class Api::V1::PostsController < Api::BaseController
  def index
    posts = current_user_api.posts.includes(:hash_tags, image_attachment: :blob).order(created_at: :desc)
    render json: posts.map { |post| post_json(post) }
  end

  def show
    post = current_user_api.posts.find(params[:id])
    render json: post_json(post)
  end

  def create
    post = current_user_api.posts.new(post_params)
    if post.save
      render json: post_json(post), status: :created
    else
      render json: { message: post.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def destroy
    post = current_user_api.posts.find(params[:id])
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
      image_url: post.image.attached? ? Rails.application.routes.url_helpers.rails_blob_path(post.image, only_path: true) : nil,
      hash_tags: post.hash_tags.map(&:name),
      created_at: post.created_at
    }
  end
end
