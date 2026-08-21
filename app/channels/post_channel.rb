class PostChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find_by(id: params[:id])
    return reject unless post

    stream_for post
    stream_for [ post, current_user ] if current_user
  end
end
