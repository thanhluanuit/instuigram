class IndexPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    post.__elasticsearch__.index_document
  end
end
