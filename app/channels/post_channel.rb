class PostChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find_by(id: params[:id])
    post ? stream_for(post) : reject
  end
end
